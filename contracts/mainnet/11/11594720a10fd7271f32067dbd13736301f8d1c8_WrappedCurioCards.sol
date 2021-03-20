//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./ERC1155.sol";

interface CurioCards{
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function transfer(address _to, uint256 _value) external returns (bool success);
}

contract WrappedCurioCards is ERC1155 {
    using SafeMath for uint256;
    using Address for address;
    string metadataURI="https:/api.wrap.cards/card/{id}";

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;
    // id => contracts
    address[] contracts=[
        0x6Aa2044C7A0f9e2758EdAE97247B03a0D7e73d6c //1
        ,0xE9A6A26598B05dB855483fF5eCc5f1d0C81140c8
        ,0x3f8131B6E62472CEea9cb8Aa67d87425248a3702
        ,0x4F1694be039e447B729ab11653304232Ae143C69
        ,0x5a3D4A8575a688b53E8b270b5C1f26fd63065219// 5
        ,0x1Ca6AC0Ce771094F0F8a383D46BF3acC9a5BF27f
        ,0x2647bd8777e0C66819D74aB3479372eA690912c3
        ,0x2FCE2713a561bB019BC5A110BE0A19d10581ee9e
        ,0xbf4Cc966F1e726087c5C55aac374E687000d4d45
        ,0x72b34d637C0d14acE58359Ef1bF472E4b4c57125// 10
        ,0xb36c87F1f1539c5FC6f6e7b1C632e1840C9B66b4
        ,0xD15af10A258432e7227367499E785C3532b50271
        ,0x2d922712f5e99428c65b44f09Ea389373d185bB3
        ,0x0565ac44e5119a3224b897De761a46A92aA28ae8
        ,0xdb7F262237Ad8acca8922aA2c693a34D0d13e8fe // 15
        ,0x1b63532CcB1FeE0595c7fe2Cb35cFD70ddF862Cd
        ,0xF59536290906F204C3c7918D40C1Cc5f99643d0B
        ,0xA507D9d28bbca54cBCfFad4BB770C2EA0519F4F0
        ,0xf26BC97Aa8AFE176e275Cf3b08c363f09De371fA
        ,0xD0ec99E99cE22f2487283A087614AEe37F6B1283 // 20
        ,0xB7A5a84Ff90e8Ef91250fB56c50a7bB92a6306EE
        ,0x148fF761D16632da89F3D30eF3dFE34bc50CA765
        ,0xCDE7185B5C3Ed9eA68605a960F6653AA1a5b5C6C
        ,0xE67dad99c44547B54367E3e60fc251fC45a145C6
        ,0xC7f60C2b1DBDfd511685501EDEb05C4194D67018 // 25
        ,0x1cB5BF4Be53eb141B56f7E4Bb36345a353B5488c
        ,0xFb9F3fa2502d01d43167A0A6E80bE03171DF407E
        ,0x59D190e8A2583C67E62eEc8dA5EA7f050d8BF27e
        ,0xD3540bCD9c2819771F9D765Edc189cBD915FEAbd
        ,0x7F5B230Dc580d1e67DF6eD30dEe82684dD113D1F
        // 17 B
        ,0xE0B5E6F32d657e0e18d4B3E801EBC76a5959e123
    ];

    
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
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

    function wrap(uint256 id,uint256 amount) public{
        require(id>0 && id<=30 || id==172);
        uint256 index = id-1;
        address contractaddress = (id != 172) ? contracts[index] : contracts[30];
        CurioCards cards=CurioCards(contractaddress);
        require(cards.transferFrom(msg.sender,address(this),amount));
        mint(id,msg.sender,amount);
    }

    function unwrap(uint256 id,uint256 amount) public{
        require(id>0 && id<=30 || id==172);
        require(balances[id][msg.sender]>=amount);
        uint256 index = id-1;
        address contractaddress = (id != 172) ? contracts[index] : contracts[30];
        CurioCards cards=CurioCards(contractaddress);
        balances[id][msg.sender] = balances[id][msg.sender].sub(amount);
        require(cards.transfer(msg.sender,amount));
        emit TransferSingle(address(0x0),msg.sender, msg.sender,id , amount);
    }

    function setBaseURI(string calldata _uri) public onlyOwner{
        metadataURI=_uri;
    }

    function uri(uint256) public view returns (string memory) {
        return metadataURI;
    }
}