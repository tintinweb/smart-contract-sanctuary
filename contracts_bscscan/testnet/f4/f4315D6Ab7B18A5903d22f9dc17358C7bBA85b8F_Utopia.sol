pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

/**
 * @title Utopia
 * @author Reza Bakhshandeh <reza[dot]bakhshandeh[at]gmail[dot]com>
 */

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Utopia{
    using SafeMath for uint256;

    struct Land{
        int256 x1;
        int256 x2;
        int256 y1;
        int256 y2;
        uint256 time;
        string hash;
    }

    // admins
    mapping(address => bool) public adminsMap;
    address[] public admins;

    address[] public owners;
    mapping(address => Land[]) public lands;

    bool public allowPublicAssign = true;

    address payable public fundsWallet = 0x22fd697B06Fee6F5c5Df5cdd4283BD45cc73B056;

    uint256 public unitLandPrice = 0.0001 ether;

    constructor() public{
        admins[admins.length++] = msg.sender;
        adminsMap[msg.sender] = true;
    }

    modifier isPublic(){
        require(allowPublicAssign);
        _;
    }

    modifier isAdmin(){
        require(adminsMap[msg.sender]);
        _;
    }

    function getOwners() view public returns (address[] memory) {
        return owners;
    }

    
    function getLands(address owner) view public returns (Land[] memory) {
        return lands[owner];
    }

    function getLand(address owner, uint256 index) 
    view public returns (
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2,
        uint256 time, string memory hash) {
        
        if(lands[owner].length > index){
            x1 = lands[owner][index].x1;
            x2 = lands[owner][index].x2;
            y1 = lands[owner][index].y1;
            y2 = lands[owner][index].y2;
            time = lands[owner][index].time;
            hash = lands[owner][index].hash;
        }
    }


    function assignLand(int256 x1, 
        int256 y1, int256 x2, int256 y2, string memory hash)
                isPublic public payable{

        uint256 cost = abs(x2-x1) * abs(y2-y1) * unitLandPrice;
        assert(msg.value >= cost);

        //Finance(fundsWallet).deposit.value(msg.value)(address(0), msg.value, "Assign Land");
        fundsWallet.transfer(msg.value);

        if(!(lands[msg.sender].length > 0)){
            owners[owners.length++] = msg.sender;
        }
        lands[msg.sender].push(Land(
            x1,
            x2,
            y1,
            y2,
            now,
            hash
        ));
    }

    function adminAssignLand(int256 x1, 
        int256 y1, int256 x2, int256 y2, address addr) public isAdmin{
        if(!(lands[addr].length > 0)){
            owners[owners.length++] = addr;
        }

        lands[addr].push(Land(
            x1,
            x2,
            y1,
            y2,
            now,
            ""
        ));
    }

    function adminSetIsPublic(bool val) isAdmin public{
        allowPublicAssign = val;
    }

    function adminSetUnitLandPrice(uint256 price) isAdmin public{
        unitLandPrice = price;
    }

    function adminSetFundsWallet(address payable _fundsWallet) isAdmin public{
        fundsWallet = _fundsWallet;
    }

    function addAdmin(address addr) isAdmin public{
        assert(addr != address(0));
        admins[admins.length++] = addr;
        adminsMap[addr] = true;
    }

    function updateLand(string memory hash, uint256 index) public returns (bool){
        require(index < lands[msg.sender].length, "!owner");
        lands[msg.sender][index].hash = hash;
        return true;
    }

    function transferLand(uint256 index, address _to) public returns(bool){
        require(index < lands[msg.sender].length, "!owner");
        // add the land to _to
        Land memory l = lands[msg.sender][index];
        lands[_to].push(Land(
            l.x1,
            l.x2,
            l.y1,
            l.y2,
            l.time,
            l.hash
        ));

        //remove from current owner
        lands[msg.sender][index] = lands[msg.sender][lands[msg.sender].length-1];
        lands[msg.sender].length--;
        return true;
    }

    function landPrice(int256 x1, 
        int256 y1, int256 x2, int256 y2)
                view public returns(uint256){
        return abs(x2-x1) * abs(y2-y1) * unitLandPrice;
    }

    function abs(int256 x) view public returns (uint256) {
        return uint256(x > 0 ? x : -1*x);
    }
}

