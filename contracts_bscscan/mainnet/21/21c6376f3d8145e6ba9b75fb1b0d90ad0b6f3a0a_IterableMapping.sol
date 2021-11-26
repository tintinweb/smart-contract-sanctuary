/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**
°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
°°°°°°°°__This library is deployed by the SnoopDog Token contract__°°°°°°°°
°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--->> SnoopDog contract address: 0x0782a0252ab7ee8c6175439ba155761faf5d8595
***************************************************************************
***************************************************************************
---------------->>  Telegram: @SnoopDogToken  <<---------------------------
---------------->>  Website: https://www.SnoopDog.it  <<-------------------
---------------->>  Email: [email protected]  <<---------------------------
---------------->>  Twitter: @SnoopDogToken  <<----------------------------
***************************************************************************
***************************************************************************
https://bscscan.com/address/0x0782a0252ab7ee8c6175439ba155761faf5d8595
https://www.dextools.io/app/bsc/pair-explorer/0xc38aa0886d57fe3a5b473b9f97a2b1ae1c3d4802

 ███████╗███╗   ██╗ ██████╗  ██████╗ ██████╗ ██████╗  ██████╗  ██████╗ 
██╔════╝████╗  ██║██╔═══██╗██╔═══██╗██╔══██╗██╔══██╗██╔═══██╗██╔════╝ 
███████╗██╔██╗ ██║██║   ██║██║   ██║██████╔╝██║  ██║██║   ██║██║  ███╗
╚════██║██║╚██╗██║██║   ██║██║   ██║██╔═══╝ ██║  ██║██║   ██║██║   ██║
███████║██║ ╚████║╚██████╔╝╚██████╔╝██║     ██████╔╝╚██████╔╝╚██████╔╝
╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═════╝  ╚═════╝  ╚═════╝ 

                                                                       
  █████████                                         ██████████                    
 ███░░░░░███                                       ░░███░░░░███                   
░███    ░░░  ████████    ██████   ██████  ████████  ░███   ░░███  ██████   ███████
░░█████████ ░░███░░███  ███░░███ ███░░███░░███░░███ ░███    ░███ ███░░███ ███░░███
 ░░░░░░░░███ ░███ ░███ ░███ ░███░███ ░███ ░███ ░███ ░███    ░███░███ ░███░███ ░███
 ███    ░███ ░███ ░███ ░███ ░███░███ ░███ ░███ ░███ ░███    ███ ░███ ░███░███ ░███
░░█████████  ████ █████░░██████ ░░██████  ░███████  ██████████  ░░██████ ░░███████
 ░░░░░░░░░  ░░░░ ░░░░░  ░░░░░░   ░░░░░░   ░███░░░  ░░░░░░░░░░    ░░░░░░   ░░░░░███
                                          ░███                            ███ ░███
                                          █████                          ░░██████ 
                                         ░░░░░                            ░░░░░░  
										                                                                                         
      #######                                            ##### ##                          
    /       ###                                       /#####  /##                          
   /         ##                                     //    /  / ###                         
   ##        #                                     /     /  /   ###                        
    ###                                                 /  /     ###                       
   ## ###      ###  /###     /###     /###     /###    ## ##      ##    /###     /###      
    ### ###     ###/ #### / / ###  / / ###  / / ###  / ## ##      ##   / ###  / /  ###  /  
      ### ###    ##   ###/ /   ###/ /   ###/ /   ###/  ## ##      ##  /   ###/ /    ###/   
        ### /##  ##    ## ##    ## ##    ## ##    ##   ## ##      ## ##    ## ##     ##    
          #/ /## ##    ## ##    ## ##    ## ##    ##   ## ##      ## ##    ## ##     ##    
           #/ ## ##    ## ##    ## ##    ## ##    ##   #  ##      ## ##    ## ##     ##    
            # /  ##    ## ##    ## ##    ## ##    ##      /       /  ##    ## ##     ##    
  /##        /   ##    ## ##    ## ##    ## ##    ## /###/       /   ##    ## ##     ##    
 /  ########/    ###   ### ######   ######  ####### /   ########/     ######   ########    
/     #####       ###   ### ####     ####   ###### /       ####        ####      ### ###   
|                                           ##     #                                  ###  
 \)                                         ##      ##                          ####   ### 
                                            ##                                /######  /#  
                                             ##                              /     ###/   
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library IterableMapping {
    // Iterable mapping from address to uint; external library which will be deployed upon contract creation
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}