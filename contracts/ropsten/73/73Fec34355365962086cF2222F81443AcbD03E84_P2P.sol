/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.5.16;

contract P2P {
    string name = "P2P_";
    struct Chat {
        uint256 length;
        mapping(uint256 => bytes32) text;
    }
    struct Deal {
        mapping(address => mapping(address => Chat)) chat;
        mapping(uint256 => address) users;
        uint256 countUsers;
        bytes32 information;
        bytes32 publicKey; //can delete for opitmization and  place publicKey into information
        address creator;
    }
    struct Account {
        mapping(uint256 => uint256) myDeals;
        mapping(uint256 => uint256) deals;
        uint256 countDeals;
        uint256 countMyDeals;
    }
    
    
    mapping(uint256 => Deal) deals;
    mapping(address => Account) accounts;
    uint256 countDeals;
    
    event Message(address from, address to);
    event FinishDeal(uint256 deal,address author);
    event AddDeal(bytes32 information,address author,uint256 deal);
    event StartDeal(uint256 deal, uint256 chat);
    
    modifier _existDeal(uint256 _id) {
        require(_id < countDeals, "don't exist deal or delete deal");
        _;
    }
    modifier _isMyDeal(uint256 _id) {
        bool flag = false;
        for (uint256 i = 0; i < accounts[msg.sender].countMyDeals; i++) {
            if (accounts[msg.sender].myDeals[i] == _id) flag = true;
        }
        require(flag, "u have not this deal");
        _;
    }
    modifier _isNotMyDeal(uint256 _id) {
        bool flag = true;
        for (uint256 i = 0; i < accounts[msg.sender].countMyDeals; i++) {
            if (accounts[msg.sender].myDeals[i] == _id) flag = false;
        }
        require(flag, "u have not this deal");
        _;
    }

    function isMyDeal(uint256 _id) public view returns (bool) {
        bool flag = false;
        for (uint256 i = 0; i < accounts[msg.sender].countMyDeals; i++) {
            if (accounts[msg.sender].myDeals[i] == _id) flag = true;
        }
        return flag;
    }

    function getCountDeals() public view returns (uint256) {
        return countDeals;
    }

    function getInformationDealByID(uint256 _id)
        public
        view
        _existDeal(_id)
        returns (bytes32, address)
    {
        return (deals[_id].information, deals[_id].creator);
    }

    function createDeal(bytes32 _information, bytes32 _publicKey) public
    returns(uint256)
    {
        accounts[msg.sender].myDeals[
            accounts[msg.sender].countMyDeals++
        ] = countDeals;
        deals[countDeals].publicKey = _publicKey;
        deals[countDeals].creator=msg.sender;
        deals[countDeals].information = _information;
        emit AddDeal(_information,msg.sender,countDeals);
        return countDeals++;
    }

    function startDeal(uint256 _id, bytes32 _publicKey)
        public
        _existDeal(_id)
        _isNotMyDeal(_id)
    {
        deals[_id].chat[msg.sender][deals[_id].creator].text[0] = _publicKey;
        deals[_id].chat[deals[_id].creator][msg.sender].text[0] = deals[_id]
            .publicKey;
        deals[_id].chat[msg.sender][deals[_id].creator].length = 1;
        deals[_id].chat[deals[_id].creator][msg.sender].length = 1;
        deals[_id].users[deals[_id].countUsers] = msg.sender;
        accounts[msg.sender].deals[accounts[msg.sender].countDeals++] = _id;
        emit StartDeal(_id,deals[_id].countUsers++);
    }

    function sendMessage(
        uint256 _id,
        bytes32 _text,
        address _address
    ) public _existDeal(_id) {
        deals[_id].chat[msg.sender][_address].text[
            deals[_id].chat[msg.sender][_address].length++
        ] = _text;
        emit Message(msg.sender, _address);
    }

    function finishDeal(uint256 _id) public _existDeal(_id) _isMyDeal(_id) {
        for (uint256 i = 0; i < accounts[msg.sender].countMyDeals; i++) {
            if (accounts[msg.sender].myDeals[i] == _id) {
                accounts[msg.sender].myDeals[i] = accounts[msg.sender].myDeals[
                    --accounts[msg.sender].countMyDeals
                ];
                break;
            }
        }
        for (uint256 i = 0; i < deals[_id].countUsers; i++) {
            for (
                uint256 j = 0;
                i < accounts[deals[_id].users[i]].countDeals;
                i++
            ) {
                if (accounts[deals[_id].users[i]].deals[j] == _id) {
                    accounts[deals[_id].users[i]].deals[j] = accounts[
                        deals[_id].users[j]
                    ].deals[--accounts[deals[_id].users[i]].countDeals];
                    break;
                }
            }
        }
        deals[_id] = deals[countDeals--];
        emit FinishDeal(_id,msg.sender);
    }

    function getCountMyDeals() public view returns (uint256) {
        return accounts[msg.sender].countMyDeals;
    }

    function getCountActiveDeals() public view returns (uint256) {
        return accounts[msg.sender].countDeals;
    }

    function getIDMyDeals(uint256 _id) public view returns (uint256) {
        require(_id < accounts[msg.sender].countMyDeals, "dont exist deal");
        return (accounts[msg.sender].myDeals[_id]);
    }

    function getIDActiveDeals(uint256 _id) public view returns (uint256) {
        require(_id < accounts[msg.sender].countDeals, "dont exist deal");
        return (accounts[msg.sender].deals[_id]);
    }

    function getCountChat(uint256 _id)
        public
        view
        _isMyDeal(_id)
        returns (uint256)
    {
        return deals[_id].countUsers;
    }

    function getAddresChatUser(uint256 _id, uint256 _idUser)
        public
        view
        _isMyDeal(_id)
        returns (address)
    {
        return deals[_id].users[_idUser];
    }

    function getAddresDealCreator(uint256 _id)
        public
        view
        _isNotMyDeal(_id)
        returns (address)
    {
        return deals[_id].creator;
    }

    function getCountMyMessage(uint256 _id, address _input)
        public
        view
        returns (uint256)
    {
        return deals[_id].chat[msg.sender][_input].length;
    }

    function getMyMessage(
        uint256 _id,
        address _input,
        uint256 _idMessage
    ) public view returns (bytes32) {
        return deals[_id].chat[msg.sender][_input].text[_idMessage];
    }

    function getCountMessageForMe(uint256 _id, address _input)
        public
        view
        returns (uint256)
    {
        return deals[_id].chat[_input][msg.sender].length;
    }

    function getMessageForMe(
        uint256 _id,
        address _input,
        uint256 _idMessage
    ) public view returns (bytes32) {
        return deals[_id].chat[_input][msg.sender].text[_idMessage];
    }

    function getName() public view returns (string memory) {
        return name;
    }
}