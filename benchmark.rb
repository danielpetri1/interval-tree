require 'benchmark'
require_relative "lib/two_lists_iterative_median"
require_relative "lib/two_lists_iterative_average"
require_relative "lib/one_list_recursive_average"
require_relative "lib/one_list_recursive_median"
require_relative "lib/one_list_iterative_average"
require_relative "lib/one_list_iterative_median"

include TwoListsIterativeMedian
include TwoListsIterativeAverage
include OneListRecursiveAverage
include OneListRecursiveMedian
include OneListIterativeAverage
include OneListIterativeMedian

def generate_random_intervals(min_start, max_end, interval_count)
    intervals = []
    
    (0...interval_count).each do |itv|
        range = [rand(min_start..max_end), rand(min_start..max_end)]
        intervals << [range.min...range.max]
    end

    intervals
end

def generate_random_point_queries(min_start, max_end, query_count)
    queries = []

    (0...query_count).each do |q|
        queries << rand(min_start..max_end)
    end

    queries
end

def pretty_print(res)
    puts "User CPU time: #{res.utime}"
    puts "System CPU time: #{res.stime}"
    puts "User + System CPU time: #{res.total}"
    puts "Total elapsed time: #{res.real}"
    puts ""
end

def main(a, b, interval_count, query_count)
    puts ""
    puts("Generating #{interval_count} intervals in range [#{a}...#{b}]")
    itvs = generate_random_intervals(a, b, interval_count)
    
    puts("Generating #{query_count} queries")
    puts ""

    queries = generate_random_point_queries(a, b, query_count)

    tree = OneListRecursiveAverage::Tree.new(itvs)

    puts "Recursive implementation with one list per node, using average (s_center not sorted)"
    res = Benchmark.measure {
        queries.each do |stab|
            tree.search(stab, unique: false, sort: false)
        end
    }

    pretty_print(res)

    tree = OneListRecursiveMedian::Tree.new(itvs)

    puts "Recursive implementation with one list per node, using median (s_center not sorted)"
    res = Benchmark.measure {
        queries.each do |stab|
            tree.search(stab, unique: false, sort: false)
        end
    }

    pretty_print(res)

    tree = OneListIterativeAverage::Tree.new(itvs)

    puts "Iterative implementation with one list per node, using average (s_center sorted)"
    res = Benchmark.measure {
        queries.each do |stab|
            tree.search(stab, unique: false, sort: false)
        end
    }

    pretty_print(res)

    tree = OneListIterativeMedian::Tree.new(itvs)

    puts "Iterative implementation with one list per node, using median (s_center sorted)"
    res = Benchmark.measure {
        queries.each do |stab|
            tree.search(stab, unique: false, sort: false)
        end
    }

    pretty_print(res)

    tree = TwoListsIterativeAverage::Tree.new(itvs)

    puts "Iterative implementation with two lists per node, using average (s_center sorted)"
    res = Benchmark.measure {
        queries.each do |stab|
            tree.search(stab, unique: false, sort: false)
        end
    }

    pretty_print(res)

    tree = TwoListsIterativeMedian::Tree.new(itvs)

    puts ""
    puts "Iterative implementation with two lists per node, using median (s_center sorted)"
    res = Benchmark.measure {
        queries.each do |stab|
            tree.search(stab, unique: false, sort: false)
        end
    }

    pretty_print(res)
end

main(0, 100_000, 10000, 100_000)
