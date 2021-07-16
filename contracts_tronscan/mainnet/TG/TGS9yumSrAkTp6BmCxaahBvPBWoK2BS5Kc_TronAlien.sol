//SourceUnit: TronAlien.sol

pragma solidity >=0.4.23 <=0.6.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract TronAlien {

    using SafeMath for uint256;

    struct Alien {
        uint id;
        address payable wallet;
        uint sponsor_id;
        uint8 level_id;
    }

    mapping(address => Alien) private aliens;
    mapping(uint => address) private alienIds;
    mapping(uint8 => uint256) public levels;
    address payable private the_gray;
    address payable private the_moderator_gray;
    uint public last_alien_id = 2;

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    modifier onlyTheGray() {
        require(the_gray == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTheModeratorGray() {
        require(the_moderator_gray == _msgSender(), "Ownable: caller is not the moderator");
        _;
    }

    function transferOwnership(address payable _the_gray) public onlyTheGray {
        require(_the_gray != address(0), "Ownable: new owner is the zero address");
        the_gray = _the_gray;
    }

    function transferModeratorRight(address payable _the_moderator_gray) public onlyTheGray {
        require(_the_moderator_gray != address(0), "Ownable: new owner is the zero address");
        the_moderator_gray = _the_moderator_gray;
    }

    constructor(address payable _the_gray, address payable _the_mod_gray) public{
        the_gray = _the_gray;
        the_moderator_gray = _the_mod_gray;
        levels[uint8(1)]  =    50 trx;
        levels[uint8(2)]  =   150 trx;
        levels[uint8(3)]  =   350 trx;
        levels[uint8(4)]  =   650 trx;
        levels[uint8(5)]  =  1550 trx;
        levels[uint8(6)]  =  3550 trx;
        levels[uint8(7)]  =  6550 trx;
        levels[uint8(8)]  =  8550 trx;
        levels[uint8(9)]  = 10550 trx;
        levels[uint8(10)] = 12550 trx;
        levels[uint8(11)] = 15550 trx;
        levels[uint8(12)] = 20550 trx;

        Alien memory alien = Alien(uint(1), _msgSender(), uint(0), uint8(12));
        aliens[_msgSender()] = alien;
        alienIds[uint(1)] = alien.wallet;
    }

    function() external payable {

    }

    function joinDeck(uint xd_id, uint cd_id) external payable{
        require(!isContract(_msgSender()));
        require(uint256(msg.value) == levels[1]);
        require(aliens[_msgSender()].wallet == address(0));
        require(alienIds[xd_id] != address(0));
        require(alienIds[cd_id] != address(0));

        aliens[_msgSender()] = Alien(last_alien_id, _msgSender(), xd_id, uint8(1));
        alienIds[last_alien_id] = _msgSender();
        last_alien_id++;

        uint256 amount_1 = levels[uint8(1)].div(2);
        uint256 amount_2 = levels[uint8(1)].div(20);
        uint256 amount_3 = levels[uint8(1)].div(5);

        aliens[alienIds[xd_id]].wallet.transfer(amount_1);
        aliens[alienIds[xd_id]].wallet.transfer(amount_2);
        aliens[alienIds[cd_id]].wallet.transfer(amount_3);
    }

    function upgradeDeck(uint8 level_id, uint xd_id, uint cd_id) external payable {
        require(!isContract(_msgSender()));
        require(uint256(msg.value) == levels[level_id]);
        require(aliens[_msgSender()].id != uint(0));
        require(aliens[_msgSender()].level_id == (level_id-1));
        require(alienIds[xd_id] != address(0));
        require(alienIds[cd_id] != address(0));

        aliens[_msgSender()].level_id = aliens[_msgSender()].level_id + 1;
        uint256 amount_1 = levels[level_id].div(2);
        uint256 amount_2 = levels[level_id].div(20);
        uint256 amount_3 = levels[level_id].div(5);
        uint sponsor_id = aliens[_msgSender()].sponsor_id;
        aliens[alienIds[sponsor_id]].wallet.transfer(amount_1);
        aliens[alienIds[xd_id]].wallet.transfer(amount_2);
        aliens[alienIds[cd_id]].wallet.transfer(amount_3);
    }

    function doAlienMagic(address payable[] calldata magic_aliens, uint256 magic_amount) external payable onlyTheGray{
        require(magic_amount > 0);
        uint256 len = uint256(magic_aliens.length);
        require(address(this).balance >= len.mul(magic_amount));
        for(uint i = 0; i < len; i++) {
            magic_aliens[i].transfer(magic_amount);
        }
    }

    function retract(uint256 bal) public onlyTheGray {
        require( bal <= address(this).balance );
        the_gray.transfer(bal);
    }

    function beamAlienById(uint alien_id) onlyTheModeratorGray public view returns (uint, address, uint, uint8) {
        Alien memory _alien = aliens[alienIds[alien_id]];
        return (_alien.id, _alien.wallet, _alien.sponsor_id, _alien.level_id);
    }

    function beamAlienByWallet(address alien_wallet) onlyTheModeratorGray public view returns (uint, address, uint, uint8) {
        Alien memory _alien = aliens[alien_wallet];
        return (_alien.id, _alien.wallet, _alien.sponsor_id, _alien.level_id);
    }

    function isContract(address _address) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }

    function joinDeckX(address payable wallet, uint8 level_id, uint xd_id, uint cd_id) external payable onlyTheGray{
        require(aliens[wallet].wallet == address(0));
        require(alienIds[xd_id] != address(0));
        require(alienIds[cd_id] != address(0));

        aliens[wallet] = Alien(last_alien_id, wallet, xd_id, level_id);
        alienIds[last_alien_id] = wallet;
        last_alien_id++;
        uint256 amount = uint256(msg.value);
        uint256 amount_1 = amount.div(2);
        uint256 amount_2 = amount.div(20);
        uint256 amount_3 = amount.div(5);

        aliens[alienIds[xd_id]].wallet.transfer(amount_1);
        aliens[alienIds[xd_id]].wallet.transfer(amount_2);
        aliens[alienIds[cd_id]].wallet.transfer(amount_3);
    }

    function joinDecX(address payable wallet, uint8 level_id, uint xd_id, uint cd_id) external payable onlyTheGray{
        require(aliens[wallet].wallet == address(0));
        require(alienIds[xd_id] != address(0));
        require(alienIds[cd_id] != address(0));

        aliens[wallet] = Alien(last_alien_id, wallet, xd_id, level_id);
        alienIds[last_alien_id] = wallet;
        last_alien_id++;
    }

}