/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: GPL-3.0-or-later


// Den of understanding, den-of-understanding,0.0.1--alpha,false

// TODO: add a "*features*" vector. Maybe a free-form string for json?

contract Stations {


    /* ------------------------------------------------------ */
    /* -- CONSTRUCTOR STATE VARIABLES                         */

    string station_name;
    string station_frequency;
    string constant stations_version = "0.0.1--alpha";
    bool immutable is_public_p;
    address immutable creator;
    uint256 immutable created_on;

    /* ------------------------------------------------------ */

    /* ------------------------------------------------------ */
    /* -- STRUCTURES                                          */

    // the Post stucture holds the address of the poster,
    // their username (at time of posting), the content
    // and a unix time of when it was posted
    struct Post {
        address author;
        string username;
        string content;
        uint256 unix_timestamp;
    }

    // the User structure holds a username (which can be
    // changed), an array of all the posts they've made, and
    // a unix timestamp of when they joined
    struct User {
        string username;
        Post [] posts;
        uint256 time_joined;
    }
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- EVENTS                                              */

    event UserJoined(
       address who,
       string username,
       uint256 unix_timestamp
    );

    event NewPost(
        address who,
        string username,
        string content,
        uint256 unix_timestamp
    );

    // this gets used to signal any error
    event StationsError(
        address who,
        string reason
    );
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- STATE VARIABLES                                     */

    // an array that holds all the addresses of the station members
    address [] all_users_of_station;

    // an array that holds all posts (in chronological order)
    Post [] all_posts;

    // a hash table that maps addresses to User structures
    mapping(address => User) station;

    // we use hash tables to check for membership (because it's
    // O(1) instead of O(n)

    // used to check membership of address
    mapping(address => bool) user_exist_map;

    // used to check if username is already used
    mapping(string => bool) username_exist_map;

    // used to store the station admins
    mapping(address => bool) admin_map;

    // used to store addresses that are allowed to join
    // [only gets used if group is private]
    mapping(address => bool) whitelist_map;
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- CONSTRUCTOR (and parameter getters)                 */

    constructor (string memory _station_name,
                 string memory _station_frequency,
                 bool _is_public_p) public {
        station_name = _station_name;
        station_frequency = _station_frequency;
        is_public_p = _is_public_p;
        creator = msg.sender;
        // creator is automatically an admin
        admin_map[msg.sender] = true;
        // creator is automatically whitelisted
        whitelist_map[msg.sender] = true;
        created_on = block.timestamp;
    }

    function station_info() public view returns (string memory,
                                                 string memory,
                                                 string memory,
                                                 address,
                                                 uint256){
        return (station_name, station_frequency, stations_version,
                creator, created_on);
    }

    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- CHECKING FUNCTIONS (VIEW)                           */

    // predicate that checks if user (address) already exists
    function user_already_in_station_p(address who)
               public view returns(bool){
        return user_exist_map[who];
    }

    // predicate that checks if username already exists / is taken
    function username_already_in_station_p(string memory a_name)
               public view returns(bool){
        return username_exist_map[a_name];
    }

    // predicate that checks if an address is in the admin group
    function is_admin_p(address who) public view returns (bool){
        return admin_map[who];
    }

    function is_allowed_in_p(address who) public view returns (bool){
        return whitelist_map[who];
    }
    /* ------------------------------------------------------ */



    /* ------------------------------------------------------ */
    /* -- ACCESSOR (VIEW or PURE) FUNCTIONS (AND DEBUGGING)   */

    function get_all_posts() public view returns (Post [] memory){
        return all_posts;
    }

    function get_all_users() public view returns (address [] memory){
        return all_users_of_station;
    }

    // uses msg.sender to get the user's username
    function whoami() public view returns (string memory){
        address who = msg.sender;
        require(user_already_in_station_p(who));
        return station[who].username;
    }

    // returns all the posts of a particular member
    function get_all_users_post(address who)
               public view returns (Post [] memory){
        require(user_already_in_station_p(who));

        return station[who].posts;
    }

    function admin_p(address who) public view returns (bool){
        return admin_map[who];
    }
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- MUTATOR FUNCTIONS                                   */

    function join_station(string memory username) public returns (bool){
        address who = msg.sender;
        uint256 timenow = block.timestamp;

        if(!is_public_p){
            if(!whitelist_map[who]){
                emit StationsError(who, "Address not whitelisted and group is private. Contact TODO!!!!!!!");
                return false;
            }
        }

        if(user_already_in_station_p(who)){
            emit StationsError(who, "User already in station");
            return false;
        }

        if(username_already_in_station_p(username)){
            emit StationsError(who, "Username already taken");
            return false;
        }

        user_exist_map[who] = true;
        username_exist_map[username] = true;
        station[who].username = username;
        station[who].time_joined = timenow;

        all_users_of_station.push(who);

        emit UserJoined(who, username, timenow);

        return true;
    }

    function make_a_post(string memory content) public returns (bool){
        address who = msg.sender;
        uint256 timenow = block.timestamp;

        if(!user_already_in_station_p(who)){
            emit StationsError(who, "User not in station");
            return false;
        }

        // does it need to be memory??
        Post memory tmp = Post(who, station[who].username, content, timenow);

        // is this wasteful? Can I store a pointer instead? Questions!
        all_posts.push(tmp);
        station[who].posts.push(tmp);

        emit NewPost(who, station[who].username, content, timenow);

        return true;
    }

    // TODO: refactor this
    function _add_post_advanced(string memory content,
                                uint256 time_posted) public returns (bool){
        address who = msg.sender;

        if(!user_already_in_station_p(who)){
            emit StationsError(who, "User not in station");
            return false;
        }

        Post memory tmp = Post(who, station[who].username, content, time_posted);

        all_posts.push(tmp);
        station[who].posts.push(tmp);

        return true;
    }

    function change_username(string memory new_username)
               public returns (bool){
        address who = msg.sender;

        if(!user_already_in_station_p(who)){
            emit StationsError(who, "User not in station");
            return false;
        }

        if(username_already_in_station_p(new_username)){
            emit StationsError(who, "Username already taken");
            return false;
        }

        string memory old_username = station[who].username;
        username_exist_map[old_username] = false;
        username_exist_map[new_username] = true;
        station[who].username = new_username;

        return true;
    }

    // TODO: sort these
    function add_admin(address someone) public returns (bool){
        require(is_admin_p(msg.sender));
        admin_map[someone] = true;
        return true;
    }

    function remove_admin(address someone) public returns (bool){
        require(is_admin_p(msg.sender));
        admin_map[someone] = false;
        return true;
    }

    function whitelist_address(address someone) public returns (bool){
        require(is_admin_p(msg.sender));
        whitelist_map[someone] = true;
        return true;
    }

    function reverse_whitelist(address someone) public returns (bool){
        require(is_admin_p(msg.sender));
        whitelist_map[someone] = false;
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
            emit StationsError(who, "unauthorized attempt to clear data");
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