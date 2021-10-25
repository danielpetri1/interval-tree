#!/usr/bin/env ruby
# frozen_string_literal: true

module TwoListsIterativeAverage
  class Tree
    def initialize(ranges, &range_factory)
      range_factory = ->(l, r) { (l...r + 1) } unless block_given?
      ranges_excl = ensure_exclusive_end([ranges].flatten, range_factory)
      @top_node = divide_intervals(ranges_excl)
    end
    attr_reader :top_node

    def divide_intervals(intervals)
      return nil if intervals.empty?

      x_center = center(intervals)
      s_center = []
      s_left = []
      s_right = []

      intervals.each do |k|
        if k.end.to_r < x_center
          s_left << k
        elsif x_center < k.begin.to_r
          s_right << k
        else
          s_center << k
        end
      end

      node_contents = [s_center.sort_by(&:begin),
                       s_center.sort_by(&:end).reverse]

      Node.new(x_center, node_contents,
               divide_intervals(s_left), divide_intervals(s_right))
    end

    # Search by range or point
    DEFAULT_OPTIONS = { unique: true, sort: true }.freeze
    def search(query, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      return nil unless @top_node

      if query.respond_to?(:begin)
        result = top_node.search(query)
        options[:unique] ? result.uniq! : result
      else
        result = point_search(top_node, query.to_r, [], options[:unique])
      end
      options[:sort] ? result.sort_by { |x| [x.begin, x.end] } : result
    end

    def ==(other)
      top_node == other.top_node
    end

    private

    def ensure_exclusive_end(ranges, range_factory)
      ranges.map do |range|
        if !range.respond_to?(:exclude_end?)
          range
        elsif range.exclude_end?
          range
        else
          range_factory.call(range.begin, range.end)
        end
      end
    end

    def center(intervals)
      (
        intervals.map(&:begin).min.to_r +
        intervals.map(&:end).max.to_r
      ) / 2
    end

    def point_search(node, point, result, unique)
      stack = [node]

      until stack.empty?
        node = stack.pop
        node_left_node = node.left_node
        node_right_node = node.right_node
        node_x_center = node.x_center
        
        if point < node_x_center
          node.s_center[0].each do |k|
            break if k.begin > point

            result << k
          end

          stack << node_left_node if node_left_node

        else
          node.s_center[1].each do |k|
            break if k.end <= point

            result << k
          end

          stack << node_right_node if node_right_node

        end
      end

      unique ? result.uniq : result
    end
  end

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
      result = []

      s_center[0].each do |k|
        k_begin = k.begin
        query_end = query.end

        break if k_begin > query_end

        k_end = k.end
        query_begin = query.begin

        k_begin_gte_q_begin = k_begin >= query_begin
        k_end_lte_q_end = k_end <= query_end
        next unless
        (
          # k is entirely contained within the query
          k_begin_gte_q_begin &&
          k_end_lte_q_end
        ) || (
          # k's start overlaps with the query
          k_begin_gte_q_begin &&
          (k_begin < query_end)
        ) || (
          # k's end overlaps with the query
          (k_end > query_begin) &&
          k_end_lte_q_end
        ) || (
          # k is bigger than the query
          (k_begin < query_begin) &&
          (k_end > query_end)
        )

        result << k
      end

      result
    end
  end
end
