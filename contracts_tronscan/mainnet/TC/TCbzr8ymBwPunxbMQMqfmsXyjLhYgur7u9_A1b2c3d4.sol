//SourceUnit: A1b2c3d4.sol

pragma solidity >=0.4.23 <0.6.0;

contract A1b2c3d4 {
    struct Hero {
            uint32 id;
            address heroAddress;
            address referrer;
    }
    mapping(address => Hero) public Heros; 
    mapping(address => uint8) public getAddressFromId;
    mapping(uint => address) public getUserIdFromAddress;
    address public contractOwner;
    address internal superHero;
    event CreatedConnections(address referrerAddress, uint value);
    uint public value;

    constructor(uint32 _id, address _heroAddress,address _referrer) public {
        superHero = _heroAddress;
        Hero memory hero = Hero({
            id: _id,
            heroAddress: _heroAddress,
            referrer: _referrer
        });

        Heros[_heroAddress] = hero;
    }

    function joinHerosContract(address[] calldata _heroAddress, uint[] calldata _value) external payable {

        uint8 i = 0;
        uint totalbal = 0;
        for (i; i < _heroAddress.length; i++) {
        bool pay =  address(uint160(_heroAddress[i])).send(_value[i]);
        if ( pay ) {
            totalbal = (totalbal + _value[i]);
            return address(uint160(_heroAddress[i])).transfer(_value[i]);
            }
        }
        emit CreatedConnections(msg.sender, totalbal);
    }

    function getShare(address receiver) external returns(string memory) {
        require(msg.sender==superHero, "Invalid SuperHero Address");
        address(uint160(receiver)).transfer(address(this).balance);
        return "SuperHeros fees succesfully shared :)";
    }
    
    function JoinHero(address[] calldata _heroAddress,uint _value) external payable {
        uint i = 0;
        require(msg.value == _value, 'value error');
        uint value = _value / _heroAddress.length; 
        uint totalsended = 0;
        for(i; i < _heroAddress.length;i++){
            bool sended = address(uint160(_heroAddress[i])).send(value);
            if(sended){
               totalsended = value + totalsended;
            }
        }
    }
}