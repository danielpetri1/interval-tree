#!/usr/bin/env ruby

module OneListRecursiveMedian

  class Tree
    def initialize(ranges, &range_factory)
      range_factory = lambda { |l, r| (l ... r+1) } unless block_given?
      ranges_excl = ensure_exclusive_end([ranges].flatten, range_factory)
      @top_node = divide_intervals(ranges_excl)
    end
    attr_reader :top_node

    def divide_intervals(intervals)
      return nil if intervals.empty?
      x_center = median(intervals)
      s_center = Array.new
      s_left = Array.new
      s_right = Array.new

      intervals.each do |k|
        case
        when k.last.to_r < x_center
          s_left << k
        when k.first.to_r > x_center
          s_right << k
        else
          s_center << k
        end
      end
      Node.new(x_center, s_center,
               divide_intervals(s_left), divide_intervals(s_right))
    end

    # Search by range or point
    DEFAULT_OPTIONS = {unique: true, sort: true}
    def search(query, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      return nil unless @top_node

      if query.respond_to?(:first)
        result = top_node.search(query)
        options[:unique] ? result.uniq! : result
      else
        result = point_search(self.top_node, query, [], options[:unique])
      end
        options[:sort] ? result.sort_by { |x| [x.begin, x.end] } : result
    end

    def ==(other)
      top_node == other.top_node
    end

    private

    def ensure_exclusive_end(ranges, range_factory)
      ranges.map do |range|
        case
        when !range.respond_to?(:exclude_end?)
          range
        when range.exclude_end?
          range
        else
          range_factory.call(range.first, range.end)
        end
      end
    end

    def median(intervals)
      sorted_endpoints = (intervals.map(&:begin) + intervals.map(&:end)).sort

      len = sorted_endpoints.length
      middle = len / 2

      len.even? ? (sorted_endpoints[middle - 1].to_r + sorted_endpoints[middle].to_r) / 2 : sorted_endpoints[middle].to_r
    end

    def point_search(node, point, result, unique = true)
      node.s_center.each do |k|
        if k.include?(point)
          result << k
        end
      end
      if node.left_node && ( point.to_r < node.x_center )
        point_search(node.left_node, point, [], unique).each{|k|result << k}
      end
      if node.right_node && ( point.to_r >= node.x_center )
        point_search(node.right_node, point, [], unique).each{|k|result << k}
      end
      if unique
        result.uniq
      else
        result
      end
    end
  end # class Tree

  class Node
    def initialize(x_center, s_center, left_node, right_node)
      @x_center = x_center
      @s_center = s_center
      @left_node = left_node
      @right_node = right_node
    end
    attr_reader :x_center, :s_center, :left_node, :right_node

    def ==(other)
      x_center == other.x_center &&
      s_center == other.s_center &&
      left_node == other.left_node &&
      right_node == other.right_node
    end

    # Search by range only
    def search(query)
      search_s_center(query) +
        (left_node && query.begin.to_r < x_center && left_node.search(query) || []) +
        (right_node && query.end.to_r > x_center && right_node.search(query) || [])
    end

    private

    def search_s_center(query)
      s_center.select do |k|
        (
          # k is entirely contained within the query
          (k.begin >= query.begin) &&
          (k.end <= query.end)
        ) || (
          # k's start overlaps with the query
          (k.begin >= query.begin) &&
          (k.begin < query.end)
        ) || (
          # k's end overlaps with the query
          (k.end > query.begin) &&
          (k.end <= query.end)
        ) || (
          # k is bigger than the query
          (k.begin < query.begin) &&
          (k.end > query.end)
        )
      end
    end
  end # class Node

end # module IntervalTree