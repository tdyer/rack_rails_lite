# A Single Route
class Route
  class << self
    # The Application name space is needed to contruct the Controller class
    # from the URL path.
    attr_accessor :app_namespace
  end

  attr_accessor :path, :controller_name, :action_name

  # Initialize each route
  def initialize(path, controller_name, action_name)
    @path, @controller_name, @action_name = path, controller_name, action_name

    if segmented_path?
      # create segments. A path segment is delimited by a a slash, '/'
      segments
      # create key segments. A key segment is a segment that has a leading ':'
      key_segments
      # create non-key segments. A segment that doesn't have leading ':'
      non_key_segments
    end
  end

  # True if this route have a path like /songs/:id or album/:album_id/songs/:id
  # False if this route have a path like /latest_songs or album/older
  def segmented_path?
    path.split('/').any? { |s| s[0] == ':' }
  end

  # TODO: cleanup, assumes we have validated that the path argument
  # is compatable with this this route's path component. We called, same?
  # earlier and it returned true.

  # Constructs a params hash given a segmented route and a URL path
  def get_params(path)
    values = []  # values from the URL path
    params = {}  # params hash to be built

    if segmented_path?
      path_segments = path.split('/').select { |s| !s.empty? }

      # remove the segments that are NOT keys, don't have ':' in the
      # segment name.
      # values will ONLY be the set of non keys.
      values = path_segments - non_key_segments

      # For every key segment from this route's path
      key_segments.each_with_index do |key, i|
        # set the params hash key from one key segment for this route.
        # and the corresponding value from the URL path segment.
        params[key.gsub(':', '').to_sym] = values[i]
      end
    end
    params
  end

  # return true if the route path matches the URL path.
  # TODO: more testing and robust checking.
  def same?(url_path)
    if segmented_path?
      # break the current url's path segments into an array
      # /songs/5/artists to ["songs", "5", "artists"]
      url_path_segments = url_path.split('/').select { |s| !s.empty? }

      # intersection of non-key segments for this route
      # and the segments for url_path
      # should be the same as this route's non-key segments
      # Ex:
      # this route's non-key segments are ['songs', 'artists']
      # the url path segments are ['songs', '5', artists']
      # then 
      # common_segments would be:
      # ['songs', 'artists']
      # which is equal to this route's non-key segments
      common_segments = non_key_segments & url_path_segments
      (segments.length == url_path_segments.length) &&
        (non_key_segments == common_segments)
    else
      # simple case where route has NO key segments
      path == url_path
    end
  end

  # array of this route's path segments, segments are delimited by slash, '/'
  def segments
    if !@segments.present?
      @segments = path.split('/').select { |s| !s.empty? }
    else
      @segments
    end
  end

  # key segments.
  # Ex: For a route with a path component like /songs/:id
  # :id is a key segment
  def key_segments
    if !@key_segments.present?
      @key_segments ||= path.split('/').map do |s|
        s if s[0] == ':'
      end.compact
    else
      @key_segments
    end
  end

  # All this route's path segments without a ':'
  def non_key_segments
    if !@non_key_segments.present?
      @non_key_segments = segments - key_segments
    else
      @non_key_segments
    end
  end

  def key_count
    path.indices.length
  end

  # Create a Controller instance and initialize.
  def controller(path)
    controller_name.constantize.new(controller_name, action_name,
                                    get_params(path))
  end

  # Run a Controller action
  def invoke_action(path)
    controller(path).send(action_name)
  end

  private

  # Construct a Controller classname
  def controller_name
    "#{self.class.app_namespace}::#{@controller_name}"
  end
end
