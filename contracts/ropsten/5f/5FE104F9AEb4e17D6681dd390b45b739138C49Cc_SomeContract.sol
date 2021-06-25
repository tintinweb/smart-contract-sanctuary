/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

contract SomeContract
{
    uint number;
    // event принимает одно значение и записывает его в блокчейн
    event someEvent(uint value);
    function setNumber(uint _number) public payable
    {
        number = _number;
        // Вызов event и передача в него значения
        emit someEvent(_number);
    }
}