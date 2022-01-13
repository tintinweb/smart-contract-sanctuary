/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


/**********************************************************************
 *                                                                    *
 *    Stations.sol                                                    *
 *                                                                    *
 *      author:    Tony Fischetti <[email protected]>          *
 *      version:   4                                                  *
 *                                                                    *
 **********************************************************************/


/*
 * Description:
 *
 *
 */

/* Specifications / flags / config
 *
 * Note:
 *   The flag <-> meaning mapping available in the project's
 *   docs will always be at least as up-to-date as the info
 *   here. Refer to that instead.
 *
 *   station type:
 *     0x0000 = microblog
 *
 *   station_flags (starting from left-most bit)
 *     0: single user (0) or multi-user (1)
 *     1: trusted [can render arbitrary HTML] (0) or untrusted (1)
 *     2: private (0) or public (1)
 *     3: undeletable (0) or deletable (1) broadcasts
 *     4: unmodifiable (0) or modifiable (1) broadcasts
 *     5: disallow (0) or allow (1) replies
 *     6: disallow (0) or allow (1) changing usernames
 *
 *   broadcast_flags (starting from left-most bit)
 *     0: user-created (0) or system-created (1)
 *     1: undeleted (0) or (1) deleted broadcast
 *     2: unedited (0) or (1) edited broadcast
 *     3: unimported (0) or imported (1) broadcast    // TODO: ?
 */


/* Example station instantiation:
 *   creator: 0xdF94fCA483faf1bf1f1f484df3e0F1B5fF216bAe
 *   name: Den of understanding
 *   frequency: den-of-understanding
 *   description: an investigation into pulling the curtain back and seeing how the machinery works
 *   type: 0x0000
 *   flags: 0x0000
 */

/* TODO:
 *  [x] delete
 *  [x] edit
 *  [x] advanced broadcast
 *  [x] import broadcast
 *  [ ] replies / reply count
 *  [ ] "acknowledgements" (and count)
 *  [ ] can I embed the transaction id in the broadcast?
 *  [ ] all the other ones
 */

contract Stations {

    /* ------------------------------------------------------ */
    /* -- STATE VARIABLES                                     */

    string            station_name;
    string            station_frequency;
    string            station_description;
    uint256 constant  stations_version = 4;
    address immutable creator;
    uint256 immutable created_on;
    bytes2 immutable  station_type;
    bytes2 immutable  station_flags;
    string            station_metadata = "";

    uint256      current_broadcast_id = 0;
    address []   all_users_of_station;
    Broadcast [] all_broadcasts;

    mapping(address => User) station;
    mapping(address => bool) user_exist_map;
    mapping(string  => bool) username_exist_map;
    mapping(address => bool) admin_map;
    mapping(address => bool) whitelist_map;

    bool sf_multiuser_p;
    bool sf_untrusted_p;
    bool sf_public_p;
    bool sf_deletable_broadcasts_p;
    bool sf_modifiable_broadcasts_p;
    bool sf_allow_replies_p;
    bool sf_allow_changing_usernames_p;
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- STRUCTURES                                          */

    struct Broadcast {
        uint256 broadcast_id;
        uint256 unix_timestamp;
        address author;
        string  username;
        string  content;
        uint256 parent;
        bytes2  broadcast_flags;
        string  broadcast_metadata;
    }

    struct User {
        string  username;
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
        Broadcast thebroadcast
    );
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- CONSTRUCTOR (and parameter getters)                 */

    constructor (address       _creator,
                 string memory _station_name,
                 string memory _station_frequency,
                 string memory _station_description,
                 bytes2        _station_type,
                 bytes2        _station_flags) public {
        creator = _creator;
        station_name = _station_name;
        station_frequency = _station_frequency;
        station_description = _station_description;
        station_type = _station_type;
        station_flags= _station_flags;

        // creator is automatically an admin
        admin_map[_creator] = true;
        // creator is automatically whitelisted
        whitelist_map[_creator] = true;
        created_on = block.timestamp;
    }

    // should get called right after contract creation
    function inaugurate_station(string memory username) public returns (bool){
        address who = msg.sender;

        require(who == creator,
                "error: need to be the station creator to inaugurate station");

        // interpreting station flags (to avoid repeated function calls)
        sf_multiuser_p                 = ((station_flags & 0x8000) > 0);
        sf_untrusted_p                 = ((station_flags & 0x4000) > 0);
        sf_public_p                    = ((station_flags & 0x2000) > 0);
        sf_deletable_broadcasts_p      = ((station_flags & 0x1000) > 0);
        sf_modifiable_broadcasts_p     = ((station_flags & 0x0800) > 0);
        sf_allow_replies_p             = ((station_flags & 0x0400) > 0);
        sf_allow_changing_usernames_p  = ((station_flags & 0x0200) > 0);

        // creates the "prime" broadcast
        Broadcast memory tmp = Broadcast(0, 0, creator, "prime-broadcast",
                                         "this is a placeholder",
                                         0, 0x8000, "");
        all_broadcasts.push(tmp);
        current_broadcast_id += 1;

        // setting username of station creator
        uint256 timenow = block.timestamp;
        user_exist_map[who] = true;
        username_exist_map[username] = true;
        station[who].username = username;
        station[who].time_joined = timenow;
        all_users_of_station.push(who);
        return true;
    }

    function station_info() public view returns (string memory,
                                                 string memory,
                                                 string memory,
                                                 uint256,
                                                 address,
                                                 uint256,
                                                 bytes2,
                                                 bytes2){
        return (station_name, station_frequency, station_description,
                stations_version, creator, created_on, station_type,
                station_flags);
    }
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- CHECKING FUNCTIONS (VIEW)                           */

    function user_already_in_station_p(address who)
               public view returns(bool){
        return user_exist_map[who];
    }

    function username_already_in_station_p(string memory a_name)
               public view returns(bool){
        return username_exist_map[a_name];
    }

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
    /* -- MORE INTERESTING FUNCTIONS                          */

    function join_station(string memory username) public returns (bool){
        address who = msg.sender;

        require(sf_multiuser_p || who==creator,
                "station is single-user. cannot join station");
        require(sf_public_p || whitelist_map[who],
                "error: address not whitelisted and group is private");
        require(!user_already_in_station_p(who),
                "error: user already in station");
        require(!username_already_in_station_p(username),
                "error: username already taken");

        uint256 timenow = block.timestamp;
        user_exist_map[who] = true;
        username_exist_map[username] = true;
        station[who].username = username;
        station[who].time_joined = timenow;

        all_users_of_station.push(who);
        emit UserJoined(who, username, timenow);
        return true;
    }

    function make_broadcast_simple(string memory content)
                                       public returns (bool){
        address who = msg.sender;
        uint256 timenow = block.timestamp;

        require(user_already_in_station_p(who), "error: user not in station");

        Broadcast memory tmp = Broadcast(current_broadcast_id, timenow,
                                         who, station[who].username,
                                         content, 0, 0x0000, "");

        all_broadcasts.push(tmp);
        emit NewBroadcast(tmp);
        current_broadcast_id += 1;
        return true;
    }

    // TODO: think about the ramifications of this
    function _make_broadcast_advanced(uint256 unix_timestamp,
                                     string memory content,
                                     uint256 parent,
                                     bytes2 broadcast_flags,
                                     string memory broadcast_metadata)
                                public returns (bool){
        address who = msg.sender;

        require(!sf_untrusted_p, "error: station needs to be 'trusted'");
        require(user_already_in_station_p(who), "error: user not in station");

        Broadcast memory tmp = Broadcast(current_broadcast_id, unix_timestamp,
                                         who, station[who].username,
                                         content, parent, broadcast_flags,
                                         broadcast_metadata);

        all_broadcasts.push(tmp);
        emit NewBroadcast(tmp);
        current_broadcast_id += 1;
        return true;
    }

    // TODO: make sure they are the same length

    // TODO: if you can verify the identity, than it's ok to
    //       manually set the time

    function _import_simple(string[] memory content) public returns (uint256){
        address who = msg.sender;
        require(who == creator,
                "error: need to be station creator to import");  // TODO: really?
        require(!sf_untrusted_p, "error: station needs to be 'trusted' to import");

        uint256 num_broadcasts_imported = 0;

        uint256 timenow = block.timestamp;

        for (uint256 i=0; i < content.length; i++) {
            Broadcast memory tmp = Broadcast(current_broadcast_id, timenow,
                                             who, station[who].username,
                                             content[i], 0, 0x0000, "");
            all_broadcasts.push(tmp);
            current_broadcast_id    += 1;
            num_broadcasts_imported += 1;
        }
        return num_broadcasts_imported;
    }

    // has to take multiple arrays; is there a way around that?
    // should you only be able to import your own?
    function _import_broadcasts(uint256 [] memory unix_timestamp,
                                address [] memory author,
                                string []  memory username,
                                string []  memory content,
                                uint256 [] memory parent,
                                bytes2 []  memory broadcast_flags,
                                string []  memory broadcast_metadata)
                                      public returns (uint256){
        address who = msg.sender;
        require(who == creator,
                "error: need to be station creator to import");  // TODO: really?
        require(!sf_untrusted_p, "error: station needs to be 'trusted' to import");

        uint256 num_broadcasts_imported = 0;

        // TODO: this is no good. fix this
        // TODO: maybe the broadcast can reference the original, in some way?

        for (uint256 i=0; i < content.length; i++) {
            Broadcast memory tmp = Broadcast(current_broadcast_id,
                                             unix_timestamp[i],
                                             author[i],
                                             username[i],
                                             content[i],
                                             parent[i],
                                             broadcast_flags[i] | 0x0800,
                                             broadcast_metadata[i]);
            all_broadcasts.push(tmp);
            current_broadcast_id    += 1;
            num_broadcasts_imported += 1;
        }
        return num_broadcasts_imported;
    }




    function change_username(string memory new_username)
               public returns (bool){
        address who = msg.sender;

        require(sf_allow_changing_usernames_p,
                "error: this station does not support changing usernames");
        require(user_already_in_station_p(who),
                "error: user not in station");
        require(!username_already_in_station_p(new_username),
                "error: username already taken");

        string memory old_username = station[who].username;
        username_exist_map[old_username] = false;
        username_exist_map[new_username] = true;
        station[who].username = new_username;
        return true;
    }

    function add_admin(address someone) public returns (bool){
        require(is_admin_p(msg.sender),
                "error: need to be an admin to add another admin");
        require(sf_multiuser_p,
                "station is single-user. cannot add admin");
        admin_map[someone] = true;
        return true;
    }

    function remove_admin(address someone) public returns (bool){
        require(msg.sender == creator,
                "error: need to be station creator to remove an admin");
        require(creator == someone,
                "error: cannot remove station creator from admin list");
        admin_map[someone] = false;
        return true;
    }

    function whitelist_address(address someone) public returns (bool){
        require(is_admin_p(msg.sender),
                "error: need to be an admin to whitelist address");
        whitelist_map[someone] = true;
        return true;
    }

    function reverse_whitelist(address someone) public returns (bool){
        require(is_admin_p(msg.sender),
                "error: need to be an admin to remove address from whitelist");
        whitelist_map[someone] = false;
        return true;
    }
    /* ------------------------------------------------------ */


    /* ------------------------------------------------------ */
    /* -- DELETIONS AND EDITING FUNCTIONS                     */

    // should the broadcaster *and* the admins be able to delete?
    function delete_broadcast(uint256 id_to_delete) public returns (bool){
        require(is_admin_p(msg.sender) ||
                  msg.sender == all_broadcasts[id_to_delete].author,
                "error: must be admin or author to delete a broadcast");
        require(id_to_delete != 0, "error: cannot delete prime broadcast");
        require(id_to_delete < current_broadcast_id,
                "error: array index out of bounds");
        bytes2 newflags = all_broadcasts[id_to_delete].broadcast_flags | 0x4000;
        all_broadcasts[id_to_delete].broadcast_flags = newflags;
        return true;
    }

    // TODO: needs more flexibility
    // NOTE: even the creator cannot edit a broadcast made by someone else
    function edit_broadcast(uint256 id_to_edit,
                            string memory newcontent) public returns (bool){
        require(msg.sender == all_broadcasts[id_to_edit].author,
                "error: must be admin or author to delete a broadcast");
        require(id_to_edit != 0, "error: cannot delete prime broadcast");
        require(id_to_edit < current_broadcast_id,
                "error: array index out of bounds");
        all_broadcasts[id_to_edit].content = newcontent;
        bytes2 newflags = all_broadcasts[id_to_edit].broadcast_flags | 0x2000;
        all_broadcasts[id_to_edit].broadcast_flags = newflags;
        return true;
    }

    // TODO: write self destruct routine
    /* ------------------------------------------------------ */

}