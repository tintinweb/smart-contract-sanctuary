/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

/**
 * Harmony (ONE) is a unique consensus platform that focuses on processing speed and validation to facilitate the creation and use of decentralized applications (DApps)And some text
 * The Harmony MainNet has an average of 2,000 transactions per second (TPS) but can reach a maximum of 24,000 TPS much higher than ETH, BSC, DOT, Fantom, ThorChain, etc
 * Harmony has launched a $1 Million Hackathon that will see the bridging of TradFi and DeFi to allow web3 and web2 developers to get together and build exciting apps, protocols, and tools.
 * 
 * Website : https://www.harmonypad.io/
 * Telegram : https://t.me/HarmonyPad
 * Telegram Ann: https://t.me/HarmonyPadAnn
 * Medium; https://harmony-pad.medium.com/
 * Twitter: https://twitter.com/harmony_pad
 * Whitepaper : https://harmonypad.s3.amazonaws.com/doc/harmonypad_whitepaper.pdf
*/
pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

pragma solidity ^0.6.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

//SeedifyFundsContract

contract MarketingContract is Ownable {
    using SafeERC20 for IERC20;

    //token attributes
    string public constant NAME = "Seedify.funds"; //name of the contract
    uint256 public immutable maxCap; // Max cap in BUSD
    uint256 public totalBUSDReceivedInAllTier; // total bnd received
    uint256 public totalBUSDInTierOne; // total BUSD for tier one
      uint256 public totalparticipants; // total participants in ido
    address payable public projectOwner; // project Owner

    // max cap per tier
    uint256 public tierOneMaxCap;

    //total users per tier
    uint256 public totalUserInTierOne;

    //max allocations per user in a tier
    uint256 public maxAllocaPerUserTierOne;

    //min allocation per user in a tier
    uint256 public minAllocaPerUserTierOne;
  
    // address array for tier one whitelist
    address[] private whitelistTierOne;

    IERC20 public ERC20Interface;
    address public tokenAddress;

    //mapping the user purchase per tier
    mapping(address => uint256) public buyInOneTier;

    // CONSTRUCTOR
    constructor(
        uint256 _maxCap,
        address payable _projectOwner,
        uint256 _tierOneValue,
        uint256 _totalparticipants,
        address _tokenAddress
    ) public {
        maxCap = _maxCap;
 
        projectOwner = _projectOwner;
        tierOneMaxCap = _tierOneValue;

        minAllocaPerUserTierOne = 10000000000000000;
  
        totalUserInTierOne = 1;

        maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
   
        totalparticipants = _totalparticipants;
        require(_tokenAddress != address(0), "Zero token address"); //Adding token to the contract
        tokenAddress = _tokenAddress;
        ERC20Interface = IERC20(tokenAddress);
    }

    // function to update the tiers value manually
    function updateTierValues(
        uint256 _tierOneValue

    ) external onlyOwner {
        tierOneMaxCap = _tierOneValue;


        maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    }

    // function to update the tiers users value manually
    function updateTierUsersValue(
        uint256 _tierOneUsersValue

    ) external onlyOwner {
        totalUserInTierOne = _tierOneUsersValue;


        maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    }

    //add the address in Whitelist tier One to invest
    function addWhitelistOne(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        whitelistTierOne.push(_address);
    }

       // check the address in whitelist tier one
    function getWhitelistOne(address _address) public view returns (bool) {
        uint256 i;
        uint256 length = whitelistTierOne.length;
        for (i = 0; i < length; i++) {
            address _addressArr = whitelistTierOne[i];
            if (_addressArr == _address) {
                return true;
            }
        }
        return false;
    }

       modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        // ERC20Interface = IERC20(tokenAddress);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    function buyTokens(uint256 amount)
        external
        _hasAllowance(msg.sender, amount)
        returns (bool)
    {
        
        require(
            totalBUSDReceivedInAllTier + amount <= maxCap,
            "buyTokens: purchase would exceed max cap"
        );

        if (getWhitelistOne(msg.sender)) {
            buyInOneTier[msg.sender] += amount;
            require(
                buyInOneTier[msg.sender] >= minAllocaPerUserTierOne,
                "your purchasing Power is so Low"
            );
            require(
                totalBUSDInTierOne + amount <= tierOneMaxCap,
                "buyTokens: purchase would exceed Tier one max cap"
            );
            require(
                buyInOneTier[msg.sender] <= maxAllocaPerUserTierOne,
                "buyTokens:You are investing more than your tier-1 limit!"
            );

            totalBUSDReceivedInAllTier += amount;
            totalBUSDInTierOne += amount;
            ERC20Interface.safeTransferFrom(msg.sender, projectOwner, amount); //changes to transfer BUSD to owner
        } else {
            revert("Not whitelisted");
        }
        return true;
    }
}