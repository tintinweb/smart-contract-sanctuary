/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: GPL-3.0-or-later

// TODO: write all scenarios to test
//         maybe a test suite?


contract Chorus {

    /* ------------------------------------------------------ */
    /* -- STRUCTURES                                          */

    // the Song stucture holds the address of the singer,
    // their stage name (at time of song singing), the
    // "lyrics", and a unix time of when it was sung
    struct Song {
        address singer;
        string stage_name;
        string lyrics;
        uint256 unix_timestamp;
    }

    // the Singer structure holds a stage name (which can be
    // changed), an array of all the songs they've sung, and
    // a unix timestamp of when they joined
    struct Singer {
        string stage_name;
        Song [] songs;
        uint256 time_joined;
    }
    /* ------------------------------------------------------ */



    /* ------------------------------------------------------ */
    /* -- EVENTS                                              */

    event SingerJoined(
       address who,
       string stage_name,
       uint256 unix_timestamp
    );

    event NewSongSung(
        address who,
        string stage_name,
        string lyrics,
        uint256 unix_timestamp
    );

    // this gets used to signal any error
    event ChorusError(
        address who,
        string reason
    );
    /* ------------------------------------------------------ */



    /* ------------------------------------------------------ */
    /* -- STATE VARIABLES                                     */

    // an array that holds all the addresses of the chorus members
    address [] all_singers_address_in_chorus;

    // an array that holds all songs sung (in chronological order)
    Song [] all_songs;

    // a hash table that maps addresses to Singer structures
    mapping(address => Singer) chorus;


    // we use hash tables to check for membership (because it's
    // O(1) instead of O(n)

    // used to check membership of address
    mapping(address => bool) singer_exist_map;

    // used to check if stage name is already used
    mapping(string => bool) stage_name_exist_map;
    /* ------------------------------------------------------ */



    /* ------------------------------------------------------ */
    /* -- CHECKING FUNCTIONS (VIEW)                           */

    // predicate that checks if singer already exists
    function singer_already_in_chorus_p(address who)
               public view returns(bool){
        return singer_exist_map[who];
    }

    // predicate that checks if stage name already exists
    function stage_name_already_in_chorus_p(string memory a_name)
               public view returns(bool){
        return stage_name_exist_map[a_name];
    }
    /* ------------------------------------------------------ */



    /* ------------------------------------------------------ */
    /* -- ACCESSOR (VIEW or PURE) FUNCTIONS (AND DEBUGGING)   */

    function get_all_songs() public view returns (Song [] memory){
        return all_songs;
    }

    function get_all_singers() public view returns (address [] memory){
        return all_singers_address_in_chorus;
    }

    // uses msg.sender to get the singer's stage name
    function whoami() public view returns (string memory){
        address who = msg.sender;
        require(singer_already_in_chorus_p(who));
        return chorus[who].stage_name;
    }

    // returns all the songs of a particular member
    function get_all_singers_songs(address who)
               public view returns (Song [] memory){
        require(singer_already_in_chorus_p(who));

        return chorus[who].songs;
    }
    /* ------------------------------------------------------ */



    /* ------------------------------------------------------ */
    /* -- MUTATOR FUNCTIONS                                   */

    function join_chorus(string memory stage_name) public returns (bool){
        address who = msg.sender;
        uint256 timenow = block.timestamp;

        if(singer_already_in_chorus_p(who)){
            emit ChorusError(who, "Singer already in chorus");
            return false;
        }

        if(stage_name_already_in_chorus_p(stage_name)){
            emit ChorusError(who, "Stage name already taken");
            return false;
        }

        singer_exist_map[who] = true;
        stage_name_exist_map[stage_name] = true;
        chorus[who].stage_name = stage_name;
        chorus[who].time_joined = timenow;

        all_singers_address_in_chorus.push(who);

        emit SingerJoined(who, stage_name, timenow);

        return true;
    }

    function sing_song(string memory lyrics) public returns (bool){
        address who = msg.sender;
        uint256 timenow = block.timestamp;

        if(!singer_already_in_chorus_p(who)){
            emit ChorusError(who, "Singer not in chorus");
            return false;
        }

        // does it need to be memory??
        Song memory tmp = Song(who, chorus[who].stage_name, lyrics, timenow);

        // is this wasteful? Can I store a pointer instead? Questions!
        all_songs.push(tmp);
        chorus[who].songs.push(tmp);

        emit NewSongSung(who, chorus[who].stage_name, lyrics, timenow);

        return true;
    }

    function change_stage_name(string memory new_stage_name)
               public returns (bool){
        address who = msg.sender;

        if(!singer_already_in_chorus_p(who)){
            emit ChorusError(who, "Singer not in chorus");
            return false;
        }

        if(stage_name_already_in_chorus_p(new_stage_name)){
            emit ChorusError(who, "Stage name already taken");
            return false;
        }

        string memory old_stage_name = chorus[who].stage_name;
        stage_name_exist_map[old_stage_name] = false;
        stage_name_exist_map[new_stage_name] = true;
        chorus[who].stage_name = new_stage_name;

        return true;
    }
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- DESTRUCTION FUNCTIONS                               */

    function degauss() public returns (bool){
        address who = msg.sender;

        // TODO: does this work?
        // TODO: try with other members
        // TODO: how will the DApp front-end handle this? does it need to?
        if(who!=0xdF94fCA483faf1bf1f1f484df3e0F1B5fF216bAe){
            emit ChorusError(who, "unauthorized attempt to clear data");
            return false;
        }

        // TODO: fix this pseudocode
        // for each item in all_singers_address_in_chorus:
        //         string stage_name = chorus[item].stage_name;
        //         delete chorus[item].songs;
        //         delete chorus[item];
        //         delete singer_exist_map[item];
        //         delete stage_name_exist_map[stage_name];
        //
        // delete all_singers_address_in_chorus;
        // delete all_songs;

        // TODO: does this get everything?

        return true;
    }

    // TODO: write self destruct routine
    /* ------------------------------------------------------ */

}