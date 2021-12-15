//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface StudentsInterface {
    function getStudentsList() external view returns (string[] memory);
}

interface TokenInterface {
    function balanceOf(address _account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function mintToken(uint256 quantity) external payable;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface AggregatorInterface {
    function latestRoundData() external view returns (uint80 roundId, int256 answer);
    function decimals() external view returns (uint8);
}

contract DEX {
    constructor() {
       getMoreTokens(1000000);
    }

    address private customer = msg.sender;
    address private tokenAddress = 0x84B60e52D2C40c00061781f8b055494cA3Ae43Ca;  
    address private tokenDAIAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa; 
    address private aggregatorETHAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address private aggregatorDAIAddress = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;    

    function getETHPrice() public view returns (uint256) {
        (,int256 _price) = AggregatorInterface(aggregatorETHAddress).latestRoundData();
        return uint(_price);
    }

    function getDAIPrice() public view returns (uint256) {
        (,int256 _price) = AggregatorInterface(aggregatorDAIAddress).latestRoundData();
        return uint(_price);
    }

    function getStudentsLength () public view returns (uint256) {
        address _studentsAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
        string[] memory studentsList = StudentsInterface(_studentsAddress).getStudentsList();
        return studentsList.length;
    }

    function getBalanceValue() public view returns (uint256) {
        uint256 _balance = TokenInterface(tokenAddress).balanceOf(address(this));
        return _balance;
    }

    function getMoreTokens(uint256 quantity) public payable {
        TokenInterface(tokenAddress).mintToken(quantity);
    }

    function buyByDAI(uint256 _daiAmount) public payable {
        uint256 _daiPrice = getDAIPrice();
        require(_daiAmount > 0, "You need to send some DAI first");

        uint256 _decimals = AggregatorInterface(aggregatorDAIAddress).decimals();
        uint256 _tokensSend = (_daiPrice * _daiAmount) / (10 ** _decimals);
        require(_tokensSend <= getBalanceValue() / (10 ** 18), "Sorry, there is not enough tokens to buy");

        uint256 _allowance = TokenInterface(tokenDAIAddress).allowance(customer, address(this));
        require(_allowance >= _daiAmount * 10 ** _decimals, "You don't have allowance for this action");

        TokenInterface(tokenDAIAddress).transferFrom(customer, address(this), _daiAmount);
        TokenInterface(tokenAddress).transfer(customer, _tokensSend);
    }

    function buyByETH() public payable {
        uint256 _studentsLength = getStudentsLength();

        uint256 _ethPrice = getETHPrice();
        uint256 _ethValue = msg.value;
        require(_ethValue  > 0, "You need to send some Ether");

        uint256 _decimals = AggregatorInterface(aggregatorETHAddress).decimals();
        uint256 _tokensSend = (_ethPrice * _ethValue) / ((10 ** _decimals) * _studentsLength);

        require(_tokensSend <= getBalanceValue(), "Sorry, there is not enough tokens to buy");

        TokenInterface(tokenAddress).transfer(customer, _tokensSend);
    }
}