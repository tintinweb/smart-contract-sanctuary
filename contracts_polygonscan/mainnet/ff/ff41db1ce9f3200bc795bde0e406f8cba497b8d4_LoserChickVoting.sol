/**
 *Submitted for verification at polygonscan.com on 2021-08-17
*/

// File: contracts\OwnableContract.sol

pragma solidity 0.6.6;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;
    address public dev;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewDev(address oldDev, address newDev);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        dev   = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner,"onlyPendingOwner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner,"onlyAdmin");
        _;
    } 

    modifier onlyDev {
        require(msg.sender == dev  || msg.sender == owner,"onlyDev");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setDev(address newDev) public onlyOwner {
        emit NewDev(dev, newDev);
        dev = newDev;
    }

}

// File: contracts\LoserChickVoting.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;


interface IChickMining {    
    function getUserInfo(uint256 _pid, address _user) external view returns (uint256 _amount, uint256 _rewardDebt, uint256 _rewardToClaim);
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract LoserChickVoting is OwnableContract{
    IChickMining chickMining = IChickMining(0x0A058646784E2cF89B24BFE12C9C2f2920342fA7);
    IERC721 trumpChick = IERC721(0x4f17c6514B9Ca3aBccfDefd12DF2dfA195A76dC4);
   
    mapping(address => uint256) public balanceOfMap;
   
    function name() external pure returns (string memory) { return "LoserChickVoting"; }
    function symbol() external pure returns (string memory) { return "vCHICKNFT"; }
    function decimals() external pure returns (uint8) { return 0; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns Chick voting power for `account`.
    function balanceOf(address account) external view returns (uint256 power) {
        uint256 balancePower = trumpChick.balanceOf(account);
        power = balancePower + balanceOfMap[account];
    }

    function updateBalanceOfMap(address[] memory account, uint256[] memory amount) public onlyAdmin{
        require(account.length == amount.length, "Parameter error.");
        for(uint256 i=0; i<account.length; i++){
            balanceOfMap[account[i]] = amount[i];
        }
    }

    function updateBalanceOf(address account, uint256 amount) public onlyAdmin{
        balanceOfMap[account] = amount;
    }

    function getBalanceOfMap(address account) public view returns(uint256){
        return balanceOfMap[account];
    }

    /// @notice Returns total power supply.
    function totalSupply() external view returns (uint256 total) {
        return trumpChick.totalSupply();
    }
}