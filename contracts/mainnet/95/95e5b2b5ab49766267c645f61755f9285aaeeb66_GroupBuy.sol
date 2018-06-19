pragma solidity ^0.4.17;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Token {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract GroupBuy {
    using SafeMath for uint256;

    enum Phase { Init, Contribute, Wait, Claim, Lock }
    uint256 private constant MAX_TOTAL = 500 ether;
    uint256 private constant MAX_EACH = 2 ether;

    address private tokenAddr;
    address private owner;
    mapping(address => uint256) private amounts;
    uint256 private totalEth;
    uint256 private totalToken;
    Phase private currentPhase;

    function GroupBuy() public {
        owner = msg.sender;
        currentPhase = Phase.Init;
    }

    modifier isOwner() {
        assert(msg.sender == owner);
        _;
    }

    // admin function
    function beginContrib() isOwner public {
        require(currentPhase == Phase.Init || currentPhase == Phase.Wait);
        currentPhase = Phase.Contribute;
    }

    function endContrib() isOwner public {
        require(currentPhase == Phase.Contribute);
        currentPhase = Phase.Wait;
        owner.transfer(address(this).balance); // collect eth to buy token
    }

    function allowClaim(address _addr) isOwner public returns (uint256) {
        require(currentPhase == Phase.Wait);
        currentPhase = Phase.Claim;
        tokenAddr = _addr;
        
        ERC20Token tok = ERC20Token(tokenAddr);
        totalToken = tok.balanceOf(this);
        require(totalToken > 0);
        return totalToken;
    }

    // rescue function
    function lock() isOwner public {
        require(currentPhase == Phase.Claim);
        currentPhase = Phase.Lock;
    }

    function unlock() isOwner public {
        require(currentPhase == Phase.Lock);
        currentPhase = Phase.Claim;
    }

    function collectEth() isOwner public {
        owner.transfer(address(this).balance);
    }

    function setTotalToken(uint _total) isOwner public {
        require(_total > 0);
        totalToken = _total;
    }

    function setTokenAddr(address _addr) isOwner public {
        tokenAddr = _addr;
    }

    function withdrawToken(address _erc20, uint _amount) isOwner public returns (bool success) {
        return ERC20Token(_erc20).transfer(owner, _amount);
    } 

    // user function
    function() public payable {
        revert();
    }

    function info() public view returns (uint phase, uint userEth, uint userToken, uint allEth, uint allToken) {
        phase = uint(currentPhase);
        userEth = amounts[msg.sender];
        userToken = totalEth > 0 ? totalToken.mul(userEth).div(totalEth) : 0;
        allEth = totalEth;
        allToken = totalToken;
    }

    function contribute() public payable returns (uint _value) {
        require(msg.value > 0);
        require(currentPhase == Phase.Contribute);
        uint cur = amounts[msg.sender];
        require(cur < MAX_EACH && totalEth < MAX_TOTAL);

        _value = msg.value > MAX_EACH.sub(cur) ? MAX_EACH.sub(cur) : msg.value;
        _value = _value > MAX_TOTAL.sub(totalEth) ? MAX_TOTAL.sub(totalEth) : _value;
        amounts[msg.sender] = cur.add(_value);
        totalEth = totalEth.add(_value);

        // return redundant eth to user
        if (msg.value.sub(_value) > 0) {
            msg.sender.transfer(msg.value.sub(_value));
        }
    }

    function claim() public returns (uint amountToken) {
        require(currentPhase == Phase.Claim);
        uint contributed = amounts[msg.sender];
        amountToken = totalEth > 0 ? totalToken.mul(contributed).div(totalEth) : 0;

        require(amountToken > 0);
        require(ERC20Token(tokenAddr).transfer(msg.sender, amountToken));
        amounts[msg.sender] = 0;
    }
}