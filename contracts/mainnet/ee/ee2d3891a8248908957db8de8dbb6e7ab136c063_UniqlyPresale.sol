/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.2;

//ERC20 functions for fallback tokens recovery
abstract contract IERC20 {
    function balanceOf(address _owner)
        external
        virtual
        returns (uint256 balance);

    function transfer(address _to, uint256 _value) external virtual;
    // can not 'returns (bool success);' because of USDT
    // and other tokens that not follow ERC20 spec fully.
}

//Uniqly presale contract
contract UniqlyPresale {
    // presale target - close presale when reached
    uint256 public immutable presaleLimit;

    // minimum pay-in per user
    uint256 public immutable minPerUser;

    // maximum pay-in per user
    uint256 public immutable maxPerUser;

    // timestamp ending presale
    uint256 public immutable presaleEnd;

    // failsafe time - fail if not properly closed after presaleEnd
    uint256 constant failSafeTime = 4 weeks;

    // owner address - will receive ETH if success
    address public owner;

    //contructor
    constructor(
        uint256 _presaleLimit, //maixmum amount to be collected
        uint256 _minPerUser, //minimum buy-in per user
        uint256 _maxPerUser, //maximum buy-in per user
        uint256 _presaleEnd, //unix timestamp of presale round end
        address _owner //privileged address
    ) {
        presaleLimit = _presaleLimit;
        minPerUser = _minPerUser;
        maxPerUser = _maxPerUser;
        presaleEnd = _presaleEnd;
        owner = _owner;
    }

    //flags need for logic (false is default)
    bool presaleEnded;
    bool presaleFailed;
    bool presaleStarted;

    // list of user balances (zero is default)
    mapping(address => uint256) private balances;

    // join presale - just send ETH to contract,
    // remember to check GAS LIMIT > 70000!
    receive() external payable {
        // only if not ended
        require(presaleStarted, "Presale not started");
        require(!presaleEnded, "Presale ended");
        // only if within time limit
        require(block.timestamp < presaleEnd, "Presale time's up");

        // record new user balance if possible
        uint256 amount = msg.value + balances[msg.sender];
        require(amount >= minPerUser, "Below buy-in");
        require(amount <= maxPerUser, "Over buy-in");
        balances[msg.sender] = amount;

        // end presale if reached limit
        if (collected() >= presaleLimit) {
            presaleEnded = true;
        }
    }

    function start() external {
        require(msg.sender == owner, "Only for Owner");
        presaleStarted = true;
    }

    // check balance of any user
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    // return balance of caller
    function balanceOf() external view returns (uint256) {
        return balances[msg.sender];
    }

    // total ETH on this contract
    function collected() public view returns (uint256) {
        return address(this).balance;
    }

    // withdraw ETH from contract
    // can be used by user and owner
    // return false if nothing to do
    function withdraw() external returns (bool) {
        if (!presaleEnded) {
            // end and fail presale if failsafe time passed
            if (block.timestamp > presaleEnd + failSafeTime) {
                presaleEnded = true;
                presaleFailed = true;
                // don't return true, you can withdraw in this call
            }
        }
        // owner withdraw - presale succeed ?
        else if (msg.sender == owner && !presaleFailed) {
            send(owner, address(this).balance);
            return true;
        }

        // presale failed, withdraw to calling user
        if (presaleFailed) {
            uint256 amount = balances[msg.sender];
            balances[msg.sender] = 0;
            send(msg.sender, amount);
            return true;
        }

        // did nothing
        return false;
    }

    //send ETH from contract to address or contract
    function send(address user, uint256 amount) private {
        bool success = false;
        (success, ) = address(user).call{value: amount}("");
        require(success, "ETH send failed");
    }

    // withdraw any ERC20 token send accidentally on this contract address to contract owner
    function withdrawAnyERC20(IERC20 token) external {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");
        token.transfer(owner, amount);
    }

    // change ownership in two steps to be sure about owner address
    address public newOwner;

    // only current owner can delegate new one
    function giveOwnership(address _newOwner) external {
        require(msg.sender == owner, "Only for Owner");
        newOwner = _newOwner;
    }

    // new owner need to accept ownership
    function acceptOwnership() external {
        require(msg.sender == newOwner, "Ure not New Owner");
        newOwner = address(0x0);
        owner = msg.sender;
    }
}