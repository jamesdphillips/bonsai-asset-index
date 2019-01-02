module ExtensionVersionsHelper
  include MarkdownHelper

  #
  # Encapsulates the logic required to return an updated_at timestamp for an
  # Atom feed, while handling possibly empty collections
  #
  # @param collection [Array<Object>] some collection to be checked
  #
  # @return [ActiveSupport::TimeWithZone] the most recent updated_at, or right
  # now
  #
  def safe_updated_at(collection)
    if collection.present?
      collection.max_by(&:updated_at).updated_at
    else
      Time.zone.now
    end
  end

  #
  # Returns an abbreviated Changelog or a description if no Changelog is
  # available for the given ExtensionVersion, suitable for showing in an Atom
  # feed.
  #
  # @param extension_version [ExtensionVersion]
  #
  # @return [String] the Changelog and/or description
  #
  def extension_atom_content(extension_version)
    if extension_version.changelog.present?
      changelog = render_document(
        extension_version.changelog, extension_version.changelog_extension
      )
      changelog_link = link_to(
        'View Full Changelog',
        extension_version_url(
          extension_version.extension,
          extension_version,
          username: extension_version.extension.owner_name,
          anchor: 'changelog'
        )
      )
      <<-EOS
        <p>#{extension_version.description}</p>
        #{HTML_Truncator.truncate(changelog, 30, ellipsis: '')}
        <p>#{changelog_link}</p>
      EOS
    else
      extension_version.description
    end
  end
  #
  # Returns the given README +content+ as it should be rendered. If the given
  # +extension+ indicates the README is formatted as Markdown, the +content+ is
  # rendered as such.
  #
  # @param content [String] the Document content
  # @param extension [String] the Document extension
  #
  # @return [String] the Document content ready to be rendered
  #
  def render_document(content, extension, repo_loc = "", version = "", hard_wrap: false)
    doc = begin
      if %w(md mdown markdown).include?(extension.downcase)
        render_markdown(content, hard_wrap: hard_wrap)
      else
        content
      end
    end.gsub(/src="(?!http)(.+)"/, %(src="https://github.com/#{repo_loc}/raw/#{version}/\\1")).html_safe
  end

  def download_url_for(extension_version)
    if extension_version.source_file.attached?
      rails_blob_url(extension_version.source_file)
    else
      "https://github.com/#{extension_version.github_repo}/archive/#{extension_version.version}.zip"
    end
  end

  def gather_viable_release_assets(extension_version)
    extension_version.release_assets
      .find_all(&:viable?)
      .sort_by(&:asset_url)
  end

  def determine_viable_platforms_and_archs(version, selected_platform, selected_arch)
    viable_github_assets    = version.release_assets.find_all(&:viable?)
    matching_github_assests = viable_github_assets
                                .find_all { |github_asset|
                                  (!selected_platform || github_asset.platform == selected_platform) &&
                                    (!selected_arch || github_asset.arch == selected_arch)
                                }

    platforms = matching_github_assests
                  .map(&:platform)
                  .compact
                  .uniq
                  .sort_by(&:downcase)
    archs     = matching_github_assests
                  .map(&:arch)
                  .compact
                  .uniq
                  .sort_by(&:downcase)

    return platforms, archs
  end
end
