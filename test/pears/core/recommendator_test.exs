defmodule Pears.Core.RecommendatorTest do
  use ExUnit.Case, async: true

  import TeamAssertions
  alias Pears.Core.{Team, Recommendator}

  test "does not modify team when there are no unassigned pears" do
    before_team =
      TeamBuilders.team()
      |> TeamBuilders.with(pears: 4, tracks: 2)

    after_team = Recommendator.assign_pears(before_team)

    assert after_team == before_team
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
    |> Team.add_to_track("pear1", "two pear track")
    |> Team.add_to_track("pear2", "two pear track")
    |> Team.add_to_track("pear3", "three pear track")
    |> Team.add_to_track("pear4", "three pear track")
    |> Team.add_to_track("pear5", "three pear track")
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
    |> Team.add_to_track("pear1", "two pear track")
    |> Team.add_to_track("pear2", "two pear track")
    |> Team.add_to_track("pear3", "one pear track")
    |> Recommendator.assign_pears()
    |> assert_pear_in_track("pear4", "one pear track")
  end
end