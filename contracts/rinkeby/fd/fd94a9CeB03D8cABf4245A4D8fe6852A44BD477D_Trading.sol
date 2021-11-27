//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface I_Agregator {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface I_studentsAmount {
    function getStudentsList() external view returns (string[] memory);
}

interface I_TikTakToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
}

contract Trading {

    address agregator = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;  
    address students = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
    address tikTakToken = 0x804D2d456c97918d82f5E8279329bdA8f56Ac577;

    function getPrice() public view returns (uint256) {
        ( , int256 _price, , , ) = I_Agregator(agregator).latestRoundData();
        return uint256(_price);
    }

    function getPriceDecimals() public view returns (uint256) {
        return uint256(I_Agregator(agregator).decimals());
    }

    function getStudentsAmount () public view returns (uint256) {
        I_studentsAmount _students = I_studentsAmount(students);
        string[] memory studentsList = _students.getStudentsList();
        return studentsList.length;
    }

    function buyToken() public payable {
        uint256 _price = getPrice();
        uint256 _priceDecimals = 10**getPriceDecimals();
        uint256 _students = getStudentsAmount();
        uint256 _etherValue = msg.value;
        address _buyer = msg.sender;
        uint256 _balance = I_TikTakToken(tikTakToken).balanceOf(address(this));
        uint256 _tokenAvailable = (_etherValue * _price)/(_priceDecimals * _students);
        if (_balance < _tokenAvailable) {
            (bool sent,) = _buyer.call{value: _etherValue}("Sorry, there is not enough tokens to buy");
            return;
        }
        I_TikTakToken(tikTakToken).transfer(_buyer, _tokenAvailable);
    }

}