defmodule Pears.Core.RecommendatorTest do
  use ExUnit.Case, async: true

  import TeamAssertions
  alias Pears.Core.{Team, Recommendator}

  test "does not modify team when there are no unassigned pears" do
    before_team =
      TeamBuilders.team()
      |> Team.add_track("two pear track")
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear_to_track("pear1", "two pear track")
      |> Team.add_pear_to_track("pear2", "two pear track")

    after_team = Recommendator.assign_pears(before_team)

    assert before_team == after_team
  end

  test "given one pear and one track, moves pear to track" do
    TeamBuilders.team()
    |> Team.add_track("feature track")
    |> Team.add_pear("pear1")
    |> Recommendator.assign_pears()
    |> assert_pear_in_track("pear1", "feature track")
  end

  test "given one empty track and two full tracks, moves pear to empty track" do
    TeamBuilders.team()
    |> Team.add_track("empty track")
    |> Team.add_track("two pear track")
    |> Team.add_track("three pear track")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Team.add_pear("pear4")
    |> Team.add_pear("pear5")
    |> Team.add_pear("pear6")
    |> Team.add_pear_to_track("pear1", "two pear track")
    |> Team.add_pear_to_track("pear2", "two pear track")
    |> Team.add_pear_to_track("pear3", "three pear track")
    |> Team.add_pear_to_track("pear4", "three pear track")
    |> Team.add_pear_to_track("pear5", "three pear track")
    |> Recommendator.assign_pears()
    |> assert_pear_in_track("pear6", "empty track")
  end

  test "given one empty track, one full track, and one incomplete track, moves pear to incomplete track" do
    TeamBuilders.team()
    |> Team.add_track("empty track")
    |> Team.add_track("one pear track")
    |> Team.add_track("two pear track")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Team.add_pear("pear4")
    |> Team.add_pear_to_track("pear1", "two pear track")
    |> Team.add_pear_to_track("pear2", "two pear track")
    |> Team.add_pear_to_track("pear3", "one pear track")
    |> Recommendator.assign_pears()
    |> assert_pear_in_track("pear4", "one pear track")
  end

  test "given two days of history and two empty tracks, pairs the two that haven't paired before" do
    TeamBuilders.team()
    |> Team.add_track("track one")
    |> Team.add_track("track two")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Map.put(:history, [
      [["pear1", "pear2"]],
      [["pear1", "pear3"]]
    ])
    |> Recommendator.assign_pears()
    |> Team.record_pears()
    |> assert_history([
      [["pear2", "pear3"], ["pear1"]],
      [["pear1", "pear2"]],
      [["pear1", "pear3"]]
    ])
  end

  test "leaves good choices for other people when non-optimal pair is available" do
    TeamBuilders.team()
    |> Team.add_track("track one")
    |> Team.add_track("track two")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Team.add_pear("pear4")
    |> Team.add_pear_to_track("pear3", "track one")
    |> Team.add_pear_to_track("pear4", "track two")
    |> Map.put(:history, [
      [["pear2", "pear3"]],
      [["pear1", "pear3"]],
      [["pear4", "pear1"]],
      [["pear2", "pear4"]]
    ])
    |> Recommendator.assign_pears()
    |> Team.record_pears()
    |> assert_history([
      [["pear1", "pear3"], ["pear2", "pear4"]],
      [["pear2", "pear3"]],
      [["pear1", "pear3"]],
      [["pear4", "pear1"]],
      [["pear2", "pear4"]]
    ])
  end

  test "pairs floating people when more floating people than available" do
    TeamBuilders.team()
    |> Team.add_track("track one")
    |> Team.add_track("track two")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Team.add_pear_to_track("pear3", "track one")
    |> Map.put(:history, [
      [["pear1", "pear2"]],
      [["pear1", "pear3"]]
    ])
    |> Recommendator.assign_pears()
    |> Team.record_pears()
    |> assert_history([
      [["pear2", "pear3"], ["pear1"]],
      [["pear1", "pear2"]],
      [["pear1", "pear3"]]
    ])
  end
end
