/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity 0.8.6;



// File: EventStorage.sol

contract EventStorage {

    
    struct Insulin {
        string insulinType;
        uint256 duration;
    }

    string public version;
    string[3] public INSULINS = ['ins1', 'ins2', 'ins3'];

    mapping(address => string[]) internal personalInsulins;


    event MeasureRecord (
        address indexed sender,
        uint256 timestamp,          //Unix timestamp
        uint256 glucose,       //Current blood glucose reading
        uint256 carbs, //Estimated carbohydrate intake
        uint256 units,     //Units of insulin the app has calculated for you
        Insulin insulinType // lookup table with insulin name (string) and duration in minutes 
    );

    constructor (string memory _version) {
        version = _version;
    }

    function bolus (
        uint256 _timestamp,          //Unix timestamp
        uint256 _glucose,       //Current blood glucose reading
        uint256 _carbs, //Estimated carbohydrate intake
        uint256 _units,     //Units of insulin the app has calculated for you
        Insulin calldata _insulinType // lookup table with insulin name (string) and duration in minutes 
         
    ) 
        external 
    {
        require(_timestamp > 0, "Cant be zero");
        //TODO
        //add more checks if need like above;

        emit MeasureRecord (
            msg.sender,
            _timestamp,
            _glucose,
            _carbs,
            _units,
            _insulinType
        );

    }

    function addPersonalInsulin(string memory _insulin) external {
        string[] storage ins = personalInsulins[msg.sender];
        ins.push(_insulin);
    }

    function removePersonalInsulin(uint256 _id) external {
        string[] memory insOld = personalInsulins[msg.sender];
        //We need recreate all array due https://docs.soliditylang.org/en/v0.8.6/types.html#delete
        delete personalInsulins[msg.sender];
        for (uint256 i = 0; i < insOld.length; i++) {
            if (i != _id) {
               personalInsulins[msg.sender].push(insOld[i]); 
            }
        }
    }

    function getInsulins() public view returns (string[3] memory insulins) {
        return INSULINS;
    }

    function getPersonalInsulins(address user) public view returns(string[] memory persIns) {
        return personalInsulins[user];
    }

    function getAllInsulins() public view returns (string[] memory allIns) {
        uint256 allArraysLength = INSULINS.length + personalInsulins[msg.sender].length;
        //Due https://docs.soliditylang.org/en/v0.8.6/types.html#allocating-memory-arrays
        string[] memory result  = new string[](allArraysLength);
        for (uint256 i = 0; i < INSULINS.length; i++) {
            result[i] = INSULINS[i];
        }
        //add spersonal array
        for (uint256 i = 0; i < personalInsulins[msg.sender].length; i++) {
            result[i + INSULINS.length] = personalInsulins[msg.sender][i];
        }
        return result;

    }
}