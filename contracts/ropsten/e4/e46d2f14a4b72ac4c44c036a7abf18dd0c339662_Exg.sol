/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;


library Math {
    function signedAdd(int256 a, uint256 b) internal pure returns (int256) {
        int256 c = a + int256(b);
        assert(c >= a);
        return c;
    }

    function signedSub(int256 a, uint256 b) internal pure returns (int256) {
        int256 c = a - int256(b);
        assert(c <= a);
        return c;
    }
}


contract Exg {
    using Math for int256;

    address payable public owner;
    uint128 public price; // wei/Exg
    uint8 public refPromille;
    uint120 public refRequirement; // exg

    // wei = totalSupply*weiPerExg/10**18 - sum(payoutsOf)
    // dividendsOf = balanceOf*weiPerExg/10**18 - payoutsOf
    uint256 weiPerExg;
    mapping(address => int256) payoutsOf; // wei

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint8 public constant decimals = 18;
    string public symbol = "exg";
    string public name;
    string public url;

    event Price(uint256 _price);
    event RefPromille(uint8 _refPromille);
    event RefRequirement(uint120 _refRequirement);
    event Dividends(uint256 _weiPerExg);
    event Buy(address indexed _buyer, uint256 _wei, address _ref, uint256 _weiToRef);
    event Withdraw(address indexed _owner, uint256 _wei);
    event Reinvest(address indexed _owner, uint256 _wei);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    constructor(string memory _name, string memory _url, uint128 _price, uint8 _refPromille, uint120 _refRequirement) {
        owner = payable(msg.sender);
        setName(_name);
        setUrl(_url);
        setPrice(_price);
        setRef(_refPromille, _refRequirement);
    }

    receive() external payable {
        buy(payable(address (0)));
    }

    function setOwner(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setUrl(string memory _url) public onlyOwner {
        url = _url;
    }

    function setPrice(uint128 _price) public onlyOwner {
        require(_price >= 10**9, "too small price");
        price = _price;
        emit Price(price);
    }

    function setRef(uint8 _refPromille, uint120 _refRequirement) public onlyOwner {
        if (refPromille != _refPromille) {
            refPromille = _refPromille;
            emit RefPromille(refPromille);
        }
        if (refRequirement != _refRequirement) {
            refRequirement = _refRequirement;
            emit RefRequirement(refRequirement);
        }
    }

    function dividendsOf(address _owner) public view returns (uint256) {
        // dividendsOf = balanceOf*weiPerExg/10**18 - payoutsOf

        uint256 a = balanceOf[_owner] * weiPerExg / 10**18;
        int256 b = payoutsOf[_owner];
        // a - b
        if (b < 0) {
            return a + uint256(-b);
        } else {
            uint256 c = uint256(b);
            if (c > a) {
                return 0;
            }
            return a - c;
        }
    }

    function dividends() public payable {
        // w = t*wpE/10**18 - sum(p)
        // w + in = t*(wpE + in*10**18/t)/10**18 - sum(p)
        // totalSupply > 0

        uint256 increaseWeiPerExg = msg.value * 10**18 / totalSupply;
        require(increaseWeiPerExg > 0, "too small amount of eth");
        weiPerExg += increaseWeiPerExg;
        emit Dividends(increaseWeiPerExg);
    }

    function buy(address payable _ref) public payable {
        // wei = totalSupply*weiPerExg/10**18 - sum(payoutsOf)
        // wei = (totalSupply + tokens)*weiPerExg/10**18 - (sum(payoutsOf) + tokens*weiPerExg/10**18)

        uint256 ownerWei = msg.value;
        uint256 refWei;
        if (_ref != address(0) && refPromille > 0) {
            if (_ref != msg.sender && balanceOf[_ref] >= refRequirement) {
                refWei = ownerWei * 1000 / refPromille;
                ownerWei -= refWei;
            }
        }
        uint256 tokens = msg.value * 10**18 / price;
        require(tokens > 0, "too small amount of eth");

        uint256 payout = tokens * weiPerExg / 10**18;
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedAdd(payout);
        emit Buy(msg.sender, ownerWei, _ref, refWei);

        totalSupply += tokens;
        balanceOf[msg.sender] += tokens;
        emit Transfer(address(0), msg.sender, tokens);

        owner.transfer(ownerWei);
        if (refWei > 0) {
            _ref.transfer(refWei);
        }
    }

    function withdraw() public {
        // wei = totalSupply*weiPerExg/10**18 - sum(payoutsOf)
        // wei - out = totalSupply*weiPerExg/10**18 - (sum(payoutsOf) + out)

        uint256 dividends = dividendsOf(msg.sender);
        require(dividends > 0, "zero dividends");
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedAdd(dividends);
        emit Withdraw(msg.sender, dividends);
        payable(msg.sender).transfer(dividends);
    }

    function reinvest() public {
        // wei = totalSupply*weiPerExg/10**18 - sum(payoutsOf)
        // wei - out = (totalSupply + tokens)*weiPerExg/10**18 - (sum(payoutsOf) + out + tokens*weiPerExg/10**18)

        uint256 dividends = dividendsOf(msg.sender);
        require(dividends != 0, "zero dividends");
        uint256 tokens = dividends * price / 10**18;

        uint256 payout = dividends + tokens * weiPerExg / 10**18;
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedAdd(payout);
        emit Reinvest(msg.sender, dividends);

        totalSupply += tokens;
        balanceOf[msg.sender] += tokens;
        emit Transfer(address(0), msg.sender, tokens);
    }

    function send(address _from, address _to, uint256 _value) private {
        // wei = totalSupply*weiPerExg/10**18 - sum(payoutsOf)
        // wei = totalSupply*weiPerExg/10**18 - (sum(payoutsOf) +- tokens*weiPerExg/10**18)

        require(_to != address(0), "zero recepient");

        uint256 payout = _value * weiPerExg / 10**18;
        payoutsOf[_from] = payoutsOf[_from].signedSub(payout);
        payoutsOf[_to] = payoutsOf[_to].signedAdd(payout);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        send(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        allowance[_from][msg.sender] -= _value;
        send(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "zero spender");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}