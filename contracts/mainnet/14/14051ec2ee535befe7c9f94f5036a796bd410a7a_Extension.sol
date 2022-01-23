/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

abstract contract CFMS { //Crypto Family Management Standard

    address private _owner;
    mapping(address => bool) private _manager;

    event OwnershipTransfer(address indexed newOwner);
    event SetManager(address indexed manager, bool state);

    constructor() {
        _owner = msg.sender;
        _manager[msg.sender] = true;

        emit SetManager(msg.sender, true);
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "CFMS: NOT_OWNER");
        _;  
    }

    modifier Manager() {
      require(_manager[msg.sender], "CFMS: MOT_MANAGER");
      _;  
    }

    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }

    function manager(address user) external view returns(bool) {
        return _manager[user];
    }

    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }

    function setManager(address user, bool state) external Owner {
        _manager[user] = state;
        emit SetManager(user, state);
    }

    function withdraw(address payable to, uint256 value) external Manager {
        to.transfer(value);
    }


}

interface SURREAL {
    function adminMint(address to, uint256 amount) external;
}

contract Extension is CFMS {
    
    SURREAL SS;

    uint256 private _whitePrice = 100000000000000000;
    uint256 private _whiteUserLimit = 4;
    uint256 private _whiteTotal = 1500;

    mapping(address => uint256) private _userWhiteMints; //How many times did the user mint in white lsit minting

    uint256 private _whiteMinted;

    mapping(address => bool) private _whiteAccess;
    
    constructor(address _SS) {
        SS = SURREAL(_SS);
    }

    //Read Functions======================================================================================================================================================

    function whiteListed(address user) external view returns(bool listed) {
        return _whiteAccess[user];
    } 

    function userWhiteMints(address user) external view returns(uint256 mints) {
        return _userWhiteMints[user];
    }

    function whiteMinted() public view returns(uint256 data) { return _whiteMinted; }
    
    //Moderator Functions======================================================================================================================================================

    function changeData(uint256 whitePrice, uint256 whiteUserLimit, uint256 whiteTotal) external Manager {
        _whitePrice = whitePrice;
        _whiteUserLimit = whiteUserLimit;
        _whiteTotal = whiteTotal;
    }

    function setWhiteList(address[] calldata users) external Manager {
        uint256 size = users.length;

        for(uint256 t; t < size; ++t) {
            _whiteAccess[users[t]] = true;
        }
    }
    
    //User Functions======================================================================================================================================================

    function whiteMint() external payable {
        require(_whiteAccess[msg.sender], "SURREAL: Invalid Access"); 

        uint256 amount = msg.value / _whitePrice;

        _userWhiteMints[msg.sender] += amount;
        require(_userWhiteMints[msg.sender] < _whiteUserLimit, "SURREAL: Minting Limit Reached");

        _whiteMinted += amount;
        require(_whiteMinted < _whiteTotal,"SURREAL: Insufficient White Mint Tokens");

        SS.adminMint(msg.sender, amount);
    }


}