//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "ERC1155.sol";

contract FFCards is ERC1155 {
    using SafeMath for uint256;
    using Address for address;
    string metadataURI="https://test2.on247.me/card/{id}";

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;
    // id => contracts
    
    //  IDS 31 to 60 = special version , ie card 4 = 34 (SE) , supply is 1. 
    uint256 constant CARD_COLLECTIONS=30;
    uint256[] CARD_MAX_SUPPLY=[
        1809, //1
        1603,
        1584,
        460,
        438, //5
        438,
        1865,
        2000,
        1817,
        2000,// 10
        2000,
        1837,
        2000,
        500,
        500,// 15
        500,
        500,
        492,
        492,
        500, // 20
        1547,
        500,
        250,
        333,
        222,// 25
        106,
        565,
        400,
        200,
        816
    ];

    mapping(uint256 => bool) specialMinted;
    mapping(uint256 => uint256) normalMinted;
    
    uint256 constant PRICE=0.005 ether;
    uint256 constant MAX_PER_TX=40;  // buy limit per tx
    uint256 constant DEV_FEE=5;
    address payable constant dev=payable(0x25CAF0150A6D74544724554F4edfDFA2B0E7c182);
    
    uint256 public dev_balance;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
     modifier onlyDev() {
        require(dev == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId) override
    public
    pure
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 total=(address(this)).balance.sub(dev_balance);
        payable(owner).transfer(total);
    }
    
    function dev_withdraw() public onlyDev {
        dev_balance=0;
        dev.transfer(dev_balance);
    }


    function mint(uint256 _id, address  _to, uint256  _quantity) internal {

            // Grant the items to the caller
            balances[_id][_to] = _quantity.add(balances[_id][_to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint 
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), _to, _id, _quantity);

            if (_to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, _id, _quantity, '');
            }
    }
    
    function random(uint256 odds) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%odds;
    }
    
    
    function buy(uint256 id,uint256 amount) public  payable{
        require(id>0 && id<=30,"Invalid id");
        require(msg.value==PRICE.mul(amount),"Amount sent is wrong");
        uint256 cardSupply= normalMinted[id];
        require(cardSupply<CARD_MAX_SUPPLY[id-1],"Sorry, this is card sold out!");
        require(amount<=MAX_PER_TX,"You cant mint that many tokens per tx");
        //odds increase as normal supply is minted to guarantee at least one special card will exist
        dev_balance = dev_balance.add(PRICE.mul(amount).mul(DEV_FEE).div(100));
        uint256 se_chance=CARD_MAX_SUPPLY[id-1]-cardSupply;
        se_chance=se_chance.div(amount);
        bool normal=random(se_chance)!=0;

        if(normal || specialMinted[id-1]){
          normalMinted[id]=cardSupply+1;
          mint(id,msg.sender,amount);
        }
        else{
           specialMinted[id]=true;
           mint(id+30,msg.sender,1);
           if(amount>1){
                mint(id+30,msg.sender,amount-1);
           }
        }
    }


    function setBaseURI(string calldata _uri) public onlyOwner{
        metadataURI=_uri;
    }

    function currentSupply(uint256 id) public view returns(uint256 supply){
        return normalMinted[id];
    }
    function uri(uint256) public view returns (string memory) {
        return metadataURI;
    }
}