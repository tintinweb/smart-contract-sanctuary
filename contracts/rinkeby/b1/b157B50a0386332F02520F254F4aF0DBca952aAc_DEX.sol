/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface StudentsInterface {
    function getStudentsList() external view returns (string[] memory);
}

interface TokenInterface {
    function balanceOf(address _account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mintToken(uint256 quantity) external payable;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface AggregatorInterface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer);

    function decimals() external view returns (uint8);
}

contract DEX {
    address public customer;
    address public tokenAddress;
    address public tokenDAIAddress;
    address public studentsAddress;
    address public aggregatorETHAddress;
    address public aggregatorDAIAddress;

    function initialize(address _tokenAddress, address _tokenDAIAddress) external{
        tokenAddress = _tokenAddress;
        tokenDAIAddress = _tokenDAIAddress;
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 _price) = AggregatorInterface(aggregatorETHAddress)
            .latestRoundData();
        return uint256(_price);
    }

    function getDAIPrice() public view returns (uint256) {
        (, int256 _price) = AggregatorInterface(aggregatorDAIAddress)
            .latestRoundData();
        return uint256(_price);
    }

    function getStudentsLength() public view returns (uint256) {
        string[] memory studentsList = StudentsInterface(studentsAddress)
            .getStudentsList();
        return studentsList.length;
    }

    function getBalanceValue() public view returns (uint256) {
        uint256 _balance = TokenInterface(tokenAddress).balanceOf(
            address(this)
        );
        return _balance;
    }

    function getMoreTokens(uint256 quantity) public {
        TokenInterface(tokenAddress).mintToken(quantity);
    }

    function checkAllowance() public view returns (uint256) {
        uint256 _allowance = TokenInterface(tokenDAIAddress).allowance(
            customer,
            address(this)
        );
        return _allowance;
    }

    function buyByDAI(uint256 _daiAmount) public {
        require(_daiAmount > 0, "You need to send some DAI first");

        uint256 _daiPrice = getDAIPrice();
        uint256 _decimalsAgg = AggregatorInterface(aggregatorDAIAddress)
            .decimals();
        uint256 _tokensSend = (_daiPrice * _daiAmount) / (10**_decimalsAgg);

        uint256 _decimalsDAI = TokenInterface(tokenDAIAddress).decimals();

        require(
            _tokensSend <= getBalanceValue() / (10**_decimalsDAI),
            "Sorry, there is not enough tokens to buy"
        );

        uint256 _allowance = checkAllowance();
        require(
            _allowance >= _daiAmount * 10**_decimalsDAI,
            "You dont have allowance for this action, get permission first"
        );

        TokenInterface(tokenDAIAddress).transferFrom(
            customer,
            address(this),
            _daiAmount * 10**_decimalsDAI
        );
        TokenInterface(tokenAddress).transfer(
            customer,
            _tokensSend * 10**_decimalsDAI
        );
    }

    function buyByETH() public payable {
        uint256 _studentsLength = getStudentsLength();

        uint256 _ethPrice = getETHPrice();
        uint256 _ethValue = msg.value;
        require(_ethValue > 0, "You need to send some Ether");

        uint256 _decimals = AggregatorInterface(aggregatorETHAddress)
            .decimals();
        uint256 _tokensSend = (_ethPrice * _ethValue) /
            ((10**_decimals) * _studentsLength);

        require(
            _tokensSend <= getBalanceValue(),
            "Sorry, there is not enough tokens to buy"
        );

        TokenInterface(tokenAddress).transfer(customer, _tokensSend);
    }
}