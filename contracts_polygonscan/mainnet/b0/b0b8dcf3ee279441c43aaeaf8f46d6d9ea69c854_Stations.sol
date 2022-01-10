/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

/**
 *Submitted for verification at snowtrace.io on 2022-01-08
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: GPL-3.0-or-later


// 0xdF94fCA483faf1bf1f1f484df3e0F1B5fF216bAe,Den of understanding,den-of-understanding,an investigation into pulling the curtain back and seeing how the machinery works,0,false

// TODO: add a "*features*" vector. Maybe a free-form string for json?

// TODO:
//   the nft is the station frequency


contract Stations {

    // TODO: should I really be using a uint256?
    uint256 current_broadcast_id = 1;

   enum Station_Types{ JOURNAL, MESSENGER, GROUP_CHAT, INTEREST_GROUP }
   // TODO: re-order?
   enum Broadcast_Types{ GENERIC, HTML, PHOTO, PRIME }

    /* ------------------------------------------------------ */
    /* -- CONSTRUCTOR STATE VARIABLES                         */

    string station_name;
    string station_frequency;
    string station_description;
    string constant stations_version = "0.0.2";
    bool immutable is_public_p;
    address immutable creator;
    uint256 immutable created_on;
    Station_Types immutable station_type;

    /* ------------------------------------------------------ */

    /* ------------------------------------------------------ */
    /* -- STRUCTURES                                          */

    // the Broadcast stucture holds the address of the poster,
    // their username (at time of posting), the content
    // and a unix time of when it was broadcast
    struct Broadcast {
        address author;
        string username;
        string content;
        uint256 unix_timestamp;
        uint256 broadcast_id;
        // TODO: parent
        // TODO: members below are not really implemented
        Broadcast_Types broadcast_type;
        bool deleted_p;
        bool edited_p;
        bool render_p;
    }

    // the User structure holds a username (which can be
    // changed), and a unix timestamp of when they joined
    struct User {
        string username;
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

    event NewBroadcast(
        address who,
        string username,
        string content,
        uint256 unix_timestamp,
        uint256 broadcast_id
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

    // an array that holds all broadcasts (in chronological order)
    Broadcast [] all_broadcasts;

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

    constructor (address _creator,
                 string memory _station_name,
                 string memory _station_frequency,
                 string memory _station_description,
                 Station_Types _station_type,
                 bool _is_public_p) public {
        creator = _creator;
        station_name = _station_name;
        station_frequency = _station_frequency;
        station_description = _station_description;
        station_type = _station_type;
        is_public_p = _is_public_p;
        // creator is automatically an admin
        admin_map[_creator] = true;
        // creator is automatically whitelisted
        whitelist_map[_creator] = true;
        created_on = block.timestamp;
    }

    // TODO: put this elsewhere
    function make_prime_broadcast() public returns (bool){
        Broadcast memory tmp = Broadcast(creator, "prime-broadcast",
                                         "this is a placeholder",
                                         0, 0, Broadcast_Types.PRIME,
                                         false, false, true);
        all_broadcasts.push(tmp);
    }

    function station_info() public view returns (string memory,
                                                 string memory,
                                                 string memory,
                                                 string memory,
                                                 address,
                                                 uint256,
                                                 Station_Types,
                                                 bool){
        return (station_name, station_frequency, station_description,
                stations_version, creator, created_on, station_type,
                is_public_p);
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

    function get_all_broadcasts() public view returns (Broadcast [] memory){
        return all_broadcasts;
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

    // TODO: write prime_broadcast

    function make_a_broadcast(string memory content) public returns (bool){
        address who = msg.sender;
        uint256 timenow = block.timestamp;
        uint256 thisid = current_broadcast_id;

        if(!user_already_in_station_p(who)){
            emit StationsError(who, "User not in station");
            return false;
        }

        // does it need to be memory??
        Broadcast memory tmp = Broadcast(who, station[who].username, content,
                                         timenow, thisid, Broadcast_Types.HTML,
                                         false, false, true);

        // is this wasteful? Can I store a pointer instead? Questions!
        all_broadcasts.push(tmp);

        emit NewBroadcast(who, station[who].username, content, timenow, thisid);

        current_broadcast_id += 1;

        return true;
    }

    // TODO: refactor this
    function _add_broadcast_advanced(string memory content,
                                uint256 time_broadcast) public returns (bool){
        address who = msg.sender;
        uint256 thisid = current_broadcast_id;

        if(!user_already_in_station_p(who)){
            emit StationsError(who, "User not in station");
            return false;
        }

        Broadcast memory tmp = Broadcast(who, station[who].username, content,
                                         time_broadcast, thisid,
                                         Broadcast_Types.HTML, false, false,
                                         true);

        all_broadcasts.push(tmp);

        current_broadcast_id += 1;

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

    // this one (and the next) doesn't quite count as "destruction" per-se
    // TODO: work on this
    function delete_broadcast(uint256 id_to_delete) public returns (bool){
        // TODO: need to check that it's the owner
        // TODO: or can the admin make it go away, and not the author
        // TODO: check bounds
        require(is_admin_p(msg.sender));
        all_broadcasts[id_to_delete].deleted_p = true;
        return true;
    }

    function edit_broadcast(uint256 id_to_edit,
                            string memory newcontent) public returns (bool){
        require(is_admin_p(msg.sender));
        all_broadcasts[id_to_edit].content = newcontent;
        all_broadcasts[id_to_edit].edited_p = true;
        return true;
    }

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