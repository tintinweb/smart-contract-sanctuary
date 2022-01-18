/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;


// @title erc20 token with dividends
// @notice wei = totalSupply*profitPerExg/1e18 - sum(payoutsOf)
contract Exg {
    address payable public admin;
    uint256 public price;
    uint256 public refPromille;
    uint256 public refRequirement;

    uint256 profitPerExg;
    mapping(address => int256) payoutsOf;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint8 public constant decimals = 18;
    string public constant symbol = "exg";
    string public name;
    string public url;

    event Price(uint256 _wei);
    event RefPromille(uint256 _promille);
    event RefRequirement(uint256 _exg);
    event Profit(uint256 _increaseWeiPerExg);
    event Buy(
        address indexed _buyer,
        uint256 _exg,
        uint256 _weiToAdmin,
        address _ref,
        uint256 _weiToRef
    );
    event Withdraw(address indexed _holder, uint256 _wei);
    event Reinvest(address indexed _holder, uint256 _wei, uint256 _exg);
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _exg
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _exg
    );

    constructor(
        uint256 _price,
        uint256 _refPromille,
        uint256 _refRequirement,
        string memory _name,
        string memory _url
    ) {
        admin = payable(msg.sender);
        price = _price;
        emit Price(price);
        refPromille = _refPromille;
        emit RefPromille(refPromille);
        refRequirement = _refRequirement;
        emit RefRequirement(refRequirement);
        name = _name;
        url = _url;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    receive() external payable {
        buy(payable(address(0)));
    }

    fallback() external payable {
        buy(payable(address(0)));
    }

    function setAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    function setPrice(uint256 _price) external onlyAdmin {
        require(_price >= 1e9, "small price");
        price = _price;
        emit Price(price);
    }

    function setRef(
        uint256 _refPromille,
        uint256 _refRequirement
    ) external onlyAdmin {
        if (refPromille != _refPromille) {
            require(_refPromille <= 500, "big refPromille");
            refPromille = _refPromille;
            emit RefPromille(refPromille);
        }
        if (refRequirement != _refRequirement) {
            refRequirement = _refRequirement;
            emit RefRequirement(refRequirement);
        }
    }

    function setName(string calldata _name) external onlyAdmin {
        name = _name;
    }

    function setUrl(string calldata _url) external onlyAdmin {
        url = _url;
    }

    function dividendsOf(address _holder) public view returns (uint256) {
        // dividendsOf = balanceOf*profitPerExg/1e18 - payoutsOf

        uint256 a = balanceOf[_holder] * profitPerExg / 1e18;
        int256 b = payoutsOf[_holder];
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

    function profit() external payable {
        // wei + in = totalSupply*(profitPerExg + in*1e18/totalSupply)/1e18
        //  - sum(payoutsOf)

        uint256 increase = msg.value * 1e18 / totalSupply;
        require(increase > 0, "small eth");
        profitPerExg += increase;
        emit Profit(increase);
    }

    function buy(address payable _ref) public payable {
        // wei = (totalSupply + tokens)*profitPerExg/1e18
        //  - (sum(payoutsOf) + tokens*profitPerExg/1e18)

        uint256 toAdmin = msg.value;
        uint256 exg = toAdmin * 1e18 / price;
        require(exg > 0, "small eth");
        uint256 toRef;
        if (_ref != address(0) && refPromille > 0) {
            if (_ref != msg.sender && balanceOf[_ref] >= refRequirement) {
                toRef = toAdmin * refPromille / 1000;
                toAdmin -= toRef;
            }
        }

        uint256 payout = exg * profitPerExg / 1e18;
        payoutsOf[msg.sender] = add(payoutsOf[msg.sender], payout);
        emit Buy(msg.sender, exg, toAdmin, _ref, toRef);

        totalSupply += exg;
        balanceOf[msg.sender] += exg;
        emit Transfer(address(0), msg.sender, exg);

        admin.transfer(toAdmin);
        if (toRef > 0) {
            _ref.transfer(toRef);
        }
    }

    function withdraw() external {
        // wei - out = totalSupply*profitPerExg/1e18
        //  - (sum(payoutsOf) + out)

        uint256 divs = dividendsOf(msg.sender);
        require(divs > 0, "zero divs");

        payoutsOf[msg.sender] = add(payoutsOf[msg.sender], divs);
        emit Withdraw(msg.sender, divs);

        if (divs > address(this).balance) {
            divs = address(this).balance;
        }
        payable(msg.sender).transfer(divs);
    }

    function reinvest() external {
        // wei - out = (totalSupply + tokens)*profitPerExg/1e18
        //  - (sum(payoutsOf) + out + tokens*profitPerExg/1e18)

        uint256 divs = dividendsOf(msg.sender);
        require(divs > 0, "zero dividends");
        uint256 exg = divs * 1e18 / price;

        uint256 payout = divs + exg * profitPerExg / 1e18;
        payoutsOf[msg.sender] = add(payoutsOf[msg.sender], payout);
        emit Reinvest(msg.sender, divs, exg);

        totalSupply += exg;
        balanceOf[msg.sender] += exg;
        emit Transfer(address(0), msg.sender, exg);

        if (divs > address(this).balance) {
            divs = address(this).balance;
        }
        admin.transfer(divs);
    }

    function send(address _from, address _to, uint256 _exg) private {
        // wei = totalSupply*profitPerExg/1e18
        //  - (sum(payoutsOf) +- tokens*profitPerExg/1e18)

        require(_to != address(0), "zero to");
        require(balanceOf[_from] >= _exg, "big exg");

        uint256 payout = _exg * profitPerExg / 1e18;
        payoutsOf[_from] = sub(payoutsOf[_from], payout);
        payoutsOf[_to] = add(payoutsOf[_to], payout);

        balanceOf[_from] -= _exg;
        balanceOf[_to] += _exg;
        emit Transfer(_from, _to, _exg);
    }

    function transfer(address _to, uint256 _exg) external returns (bool) {
        send(msg.sender, _to, _exg);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _exg
    ) external returns (bool) {
        require(allowance[_from][msg.sender] >= _exg, "not allowed");
        allowance[_from][msg.sender] -= _exg;
        send(_from, _to, _exg);
        return true;
    }

    function approve(address _spender, uint256 _exg) external returns (bool) {
        require(_spender != address(0), "zero spender");
        allowance[msg.sender][_spender] = _exg;
        emit Approval(msg.sender, _spender, _exg);
        return true;
    }

    function add(int256 a, uint256 b) private pure returns (int256) {
        int256 c = int256(b);
        assert(c >= 0);
        return a + c;
    }

    function sub(int256 a, uint256 b) private pure returns (int256) {
        int256 c = int256(b);
        assert(c >= 0);
        return a - c;
    }
}