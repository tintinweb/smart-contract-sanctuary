/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IBEP721 {

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mintedUsers(address _user) external view returns (bool isMinter);
    
    function HODLMintedUsers(address _user) external view returns (bool isMinter);
}

contract StakeContract {
    using SafeMath for uint256;

    IBEP721 public shitNFT;
    IBEP20 public token;
    address payable public owner;
    uint256 public constant duration = 69 days;
    uint256 public hodlerCoins = 6690;
    uint256 public bonus;

    struct Stake {
        uint256 amount;
        uint256 time;
        uint256 bonus;
        bool withdrawan;
    }

    struct User {
        uint256 totalstakeduser;
        uint256 stakecount;
        mapping(uint256 => Stake) stakerecord;
    }

    mapping(address => User) public users;
    mapping(address => bool) public diamondStaker;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: Not an owner");
        _;
    }

    event Staked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    event UnStaked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    event Withdrawn(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    constructor(address payable _owner, address _token, address _nftAdress) {
        owner = _owner;
        token = IBEP20(_token);
        shitNFT = IBEP721(_nftAdress);
        bonus = 20;
        hodlerCoins = hodlerCoins.mul(10 ** token.decimals());
    }

    function stake(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), (amount));
        User storage user = users[msg.sender];
        user.totalstakeduser = user.totalstakeduser.add(amount);
        // Reduction in time by 50% for Diamond Hands NFT.
        if(amount >= hodlerCoins || shitNFT.HODLMintedUsers(msg.sender)) {
            user.stakerecord[user.stakecount].time = block.timestamp + (duration.div(2));
            diamondStaker[msg.sender] = true; 
        } else{
            user.stakerecord[user.stakecount].time = block.timestamp + duration;                
        }
        user.stakerecord[user.stakecount].amount = amount;
        // Common Shit NFT holder will get 1% higher reward.
        if(shitNFT.mintedUsers(msg.sender)) {
            user.stakerecord[user.stakecount].bonus = amount.mul(bonus.add(10)).div(1000);            
        } else {
            user.stakerecord[user.stakecount].bonus = amount.mul(bonus).div(1000);
        }
        user.stakecount++;

        emit Staked(msg.sender, amount, block.timestamp);
    }

    function withdraw(uint256 index) public {
        User storage user = users[msg.sender];
        require(user.stakecount > index, "Invalid Stake index");
        require(
            user.stakerecord[index].time < block.timestamp,
            "cannot withdraw before time"
        );
        require(!user.stakerecord[index].withdrawan, "already withdraw");
        uint256 totalTokens = user.stakerecord[index].amount.add(
            user.stakerecord[index].bonus
        );
        user.stakerecord[index].withdrawan = true;
        token.transfer(msg.sender, totalTokens);

        emit Withdrawn(msg.sender, totalTokens, block.timestamp);
    }

    function unstake(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount > count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan, "withdraw only once");
        user.stakerecord[count].withdrawan = true;
        uint256 unstakeable = user.stakerecord[count].amount;
        token.transfer(msg.sender, unstakeable);
        user.stakerecord[count].bonus = 0;

        emit UnStaked(msg.sender, unstakeable, block.timestamp);
    }

    function stakedetails(address user, uint256 count)
        public
        view
        returns (
            uint256 _time,
            uint256 _amount,
            uint256 _bonus,
            bool _withdrawan
        )
    {
        return (
            users[user].stakerecord[count].time,
            users[user].stakerecord[count].amount,
            users[user].stakerecord[count].bonus,
            users[user].stakerecord[count].withdrawan
        );
    }

    function changeHodlerCoinsLimit(uint256 _amount) external onlyOwner {
        hodlerCoins = _amount;
    }

    function changebonuspercent(uint256 _percent) external onlyOwner {
        require(_percent > 10,"must be greater than 1%");
        bonus = _percent;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeNFT(address _new) external onlyOwner {
        shitNFT = IBEP721(_new);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}