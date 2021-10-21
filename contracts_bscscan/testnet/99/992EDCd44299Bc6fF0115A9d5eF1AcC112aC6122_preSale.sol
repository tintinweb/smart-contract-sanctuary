pragma solidity ^0.8.7;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
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

contract preSale {
    using SafeMath for uint256;

    address payable public owner;
    IBEP20 public token;

    // uint256 public tokenPerBnb;
    uint256 public preSaleTime;
    uint256 public amountRaised;
    uint256 public soldToken;
    uint256 public maxSell;
    uint256 public referralpercent;
    uint256 public preSAleStartTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public totalSupply;

    uint256[] public bonusPercent = [10, 20, 30, 40, 50];

    modifier onlyOwner() {
        require(msg.sender == owner, "Presale: Not an owner");
        _;
    }

    event BuyToken(address _user, uint256 _amount);

    constructor(address payable _owner, address _token) {
        owner = _owner;
        token = IBEP20(_token);
        // tokenPerBnb = 1000000;
        minAmount = 0.05 ether;
        maxAmount = 25 ether;
        totalSupply= 1000000000;
        preSAleStartTime = block.timestamp;
        preSaleTime = block.timestamp + 90 days;
    }

    receive() external payable {}

    // to buy token during preSale time => for web3 use
    function buyToken() public payable {
        require(block.timestamp < preSaleTime, "PreSale: PreSale over");
        require(
            block.timestamp > preSAleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(msg.value >= minAmount,"PreSale: Less than min amount");
        require(msg.value <= maxAmount,"PreSale: Greater than max amount");

        uint256 numberOfTokens = bnbToToken(msg.value);

        if (msg.value == 0.5 ether) {
            token.transferFrom(
                owner,
                msg.sender,
                numberOfTokens.add(numberOfTokens.mul(bonusPercent[0]).div(100))
            );
        } else if (msg.value == 1 ether) {
            token.transferFrom(
                owner,
                msg.sender,
                numberOfTokens.add(numberOfTokens.mul(bonusPercent[1]).div(100))
            );
        } else if (msg.value == 5 ether) {
            token.transferFrom(
                owner,
                msg.sender,
                numberOfTokens.add(numberOfTokens.mul(bonusPercent[2]).div(100))
            );
        } else if (msg.value == 10 ether) {
            token.transferFrom(
                owner,
                msg.sender,
                numberOfTokens.add(numberOfTokens.mul(bonusPercent[3]).div(100))
            );
        } else if (msg.value == 25 ether) {
            token.transferFrom(
                owner,
                msg.sender,
                numberOfTokens.add(numberOfTokens.mul(bonusPercent[4]).div(100))
            );
        }

        token.transferFrom(owner, msg.sender, numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        soldToken = soldToken.add(numberOfTokens);
        emit BuyToken(msg.sender, numberOfTokens);
    }

    //  to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 tokenPerBnb;
        if (soldToken <= 100000000 * 1e9) {
            tokenPerBnb = 1000000;
        } else if (
            soldToken > 100000000 * 1e9 && soldToken <= 200000000 * 1e9
        ) {
            tokenPerBnb = 950000;
        } else if (
            soldToken > 200000000 * 1e9 && soldToken <= 300000000 * 1e9
        ) {
            tokenPerBnb = 900000;
        } else if (
            soldToken > 300000000 * 1e9 && soldToken <= 400000000 * 1e9
        ) {
            tokenPerBnb = 850000;
        } else if (
            soldToken > 400000000 * 1e9 && soldToken <= 500000000 * 1e9
        ) {
            tokenPerBnb = 800000;
        } else if (
            soldToken > 500000000 * 1e9 && soldToken <= 600000000 * 1e9
        ) {
            tokenPerBnb = 750000;
        } else if (
            soldToken > 600000000 * 1e9 && soldToken <= 700000000 * 1e9
        ) {
            tokenPerBnb = 700000;
        } else if (
            soldToken > 700000000 * 1e9 && soldToken <= 800000000 * 1e9
        ) {
            tokenPerBnb = 650000;
        } else if (
            soldToken > 800000000 * 1e9 && soldToken <= 900000000 * 1e9
        ) {
            tokenPerBnb = 600000;
        } else if (soldToken > 9000000 * 1e9) {
            tokenPerBnb = 550000;
        }
        uint256 numberOfTokens = _amount.mul(tokenPerBnb).div(1e18);
        return numberOfTokens.mul(1e9);
    }
    function getProgress() public view returns(uint256 _percent) {
        uint256 remaining = totalSupply.sub(soldToken.div(1e9));
        remaining = remaining.mul(100).div(totalSupply);
        uint256 hundred = 100;
        return hundred.sub(remaining);
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setTotalsupply(uint256 _totalsupply) external {
        totalSupply = _totalsupply;
    }

    // to Change claim time
    function setPreSaleTime(uint256 _time) external onlyOwner {
        preSaleTime = _time;
    }

    function preSaleLimits(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyOwner
    {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    // to change preSale private Bonus
    function setBonusPercentages(
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth,
        uint256 fifth
    ) external onlyOwner {
        bonusPercent[0] = first;
        bonusPercent[1] = second;
        bonusPercent[2] = third;
        bonusPercent[3] = fourth;
        bonusPercent[4] = fifth;
    }

    // // to change price
    // function setPriceOfToken(uint256 _price) external onlyOwner {
    //     tokenPerBnb = _price;
    // }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setToken(address newtoken) public onlyOwner {
        token = IBEP20(newtoken);
    }

    function changeStartTime(uint256 _time) public onlyOwner {
        preSAleStartTime = _time;
    }

    function preSaleEndTime(uint256 _Time) public onlyOwner {
        preSaleTime = _Time;
    }

    // to draw funds for liquidity
    function migrateFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return token.allowance(owner, address(this));
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