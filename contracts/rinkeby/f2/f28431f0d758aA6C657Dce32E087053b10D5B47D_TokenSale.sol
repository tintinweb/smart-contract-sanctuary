//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface AggregatorInterface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80 roundId, uint256 answer);
}

interface StudentsInterface {
    function getStudentsList() external view returns (string[] memory);
}

interface TokenInterface {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
}

contract TokenSale {
    function getEthPrice() public view returns (uint256) {
        address _aggregatorAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;  
        (,uint256 _price) = AggregatorInterface(_aggregatorAddress).latestRoundData();
        return _price;
    }

    function getStudentsLength () public view returns (uint256) {
        address _studentsAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
        string[] memory studentsList = StudentsInterface(_studentsAddress).getStudentsList();
        return studentsList.length;
    }

    function buyToken() public payable {
        address _tokenAddress = 0x849Ef7af137dcdb6Eff6152EF8545AD02F33BF20;
        address _customer = msg.sender;

        uint256 _ethPrice = getEthPrice();
        uint256 _studentsLenghth = getStudentsLength();
        uint256 _etherValue = msg.value;
        uint256 _tokenPrice = (_etherValue * _ethPrice)/(_studentsLenghth) / 10**8;
        
        TokenInterface(_tokenAddress).transfer(_customer, _tokenPrice);
    }

}