/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity >= 0.6.0;


contract CalledContract {    
    function onlyEven(uint256 a) external pure returns(uint) {
        // assert(a > 0);
        
        uint b = 300 / a;
        require(b % 2 == 0, "Ups! Reverting");
        return b;
    }
    
    function outOfBounds(uint256 _index) external pure returns(uint) {
         uint8[4] memory someNums = [1, 2, 3, 4];
         return someNums[_index];
    }
}

contract PanicTest {
    event ReturnDataEvent(bytes someData);
    event SuccessEvent(uint _value);
    event CatchEvent(string revertReason);
    event PanicEvent(uint code);

    CalledContract public externalContract;

    constructor() public {
        externalContract = new CalledContract();
    }
    
    function execute(uint amount, uint _gas) public {
        try externalContract.onlyEven(amount) returns(uint _value) {
            emit SuccessEvent(_value);
        } catch Error(string memory revertReason) {
            emit CatchEvent(revertReason);
        // } catch Panic(uint _code) {
        //     emit PanicEvent(_code);
        // } catch (bytes memory returnData) {
        //     emit ReturnDataEvent(returnData);
        }
    }
    
    function outOfBoundsTest(uint _index) public {
        try externalContract.outOfBounds(_index) returns(uint _value) {
            emit SuccessEvent(_value);
        } catch Error(string memory revertReason) {
            emit CatchEvent(revertReason);
        // } catch Panic(uint _code) {
        //     emit PanicEvent(_code);
        // } catch (bytes memory returnData) {
        //     emit ReturnDataEvent(returnData);
        }
    }
}