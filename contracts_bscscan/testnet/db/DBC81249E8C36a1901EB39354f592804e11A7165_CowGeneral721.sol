// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IStable {
    function isStable(uint tokenId) external view returns (bool);

    function isUsing(uint tokenId) external view returns (bool);

    function changeUsing(uint tokenId, bool com_) external;

    function isApprove(address owner_, address spender, uint itemsId) external view returns (bool);

    function costItems(address addr, uint itemsId, uint amount_) external;

    function userItems(address addr, uint itemsId) external view returns (uint);


}

contract CowGeneral721 is Ownable {
    address public superMinter;
    uint currentId = 300001;
    address public stable;
    mapping(address => uint) public minters;
    uint randomSeed = 1;
    IStable public sta;
    uint public maxLife  = 35 days;
    event BornBull(address indexed sender_, uint indexed tokenId, uint life_ , uint energy_, uint attack_,uint defense_ ,uint stamina_);
    event BornCow(address indexed sender_,uint indexed tokenId,uint life_,uint energy_,uint milk_,uint milkRate_ );
    function setSuperMinter(address newSuperMinter_) public onlyOwner returns (bool) {
        superMinter = newSuperMinter_;
        return true;
    }
    
    function rand(uint256 _length) internal  returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp,randomSeed)));
        randomSeed ++;
        return random % _length + 1 ;
    }

    struct CowInfo {
        uint gender; // 1 for male,2 for femal;
        uint bornTime;
        uint energy;
        uint life;
        uint growth;
        uint checkTime;
        uint exp;
        bool isAdult;
        uint attack;
        uint stamina;
        uint defense;
        uint milk;
        uint milkRate;
    }

    struct UserInfo {
        uint balances;
        uint[] cowList;
    }
    mapping(uint => uint) public deadTime;
    mapping(address => UserInfo)public userInfo;
    mapping(uint => address)public ownerOf;
    mapping(uint => CowInfo) public cowInfoes;
    mapping(address => mapping(address => mapping(uint => bool))) public isApprove;
    mapping(address => bool) public admin;
    mapping(address => mapping(address => bool))public _operatorApprovals;
    string public myBaseURI;

    constructor()  {
        myBaseURI = '123456';
        superMinter = msg.sender;
    }
    
    function setMaxLife(uint life_) external onlyOwner{
        maxLife = life_;
    }

    modifier onlyAdmin(){
        require(admin[_msgSender()], 'not admin');
        _;
    }
    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        require(cowInfoes[tokenId_].bornTime > 0, "nonexistent token");
        return string(abi.encodePacked(myBaseURI, "/", 'normal.jpeg'));
    }

    function setAdminm(address addr, bool com_) public onlyOwner {
        admin[addr] = com_;
    }

    function getGender(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].gender;
    }

    function getHunger(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].energy;
    }

    function getAdult(uint tokenId_) external view returns (bool){
        return cowInfoes[tokenId_].isAdult;
    }

    function getPower(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].attack;
    }

    function getLife(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].life;
    }

    function getBronTime(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].bornTime;
    }

    function getGrowth(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].growth;
    }

    function setMyBaseURI(string calldata uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function _mint(address player_, uint tokenId_) internal {
        ownerOf[tokenId_] = player_;
        userInfo[player_].balances ++;
        userInfo[player_].cowList.push(tokenId_);
    }

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }


    function mint(address player, uint gender_, uint life_, uint energy_) public returns (uint256) {
        require(gender_ <= 1, 'wrong gender');
        uint tokenId = currentId;

        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        cowInfoes[currentId].gender = gender_;
        cowInfoes[currentId].life = life_;
        cowInfoes[currentId].bornTime = block.timestamp;
        cowInfoes[currentId].energy = energy_;
        cowInfoes[currentId].checkTime = block.timestamp;
        cowInfoes[currentId].isAdult = true;
        deadTime[currentId] = maxLife * life_ / 100;
        if (cowInfoes[currentId].gender == 1){
            cowInfoes[currentId].attack = 60 + rand(26);
            cowInfoes[currentId].stamina = 60 + rand(26);
            cowInfoes[currentId].defense = 60 + rand(26);
            emit BornBull(player, currentId, cowInfoes[currentId].life, cowInfoes[currentId].energy,cowInfoes[currentId].attack,cowInfoes[currentId].defense,cowInfoes[currentId].stamina);
            

        }else{
            cowInfoes[currentId].milk = 60 + rand(26);
            cowInfoes[currentId].milkRate = 60 + rand(26);
            emit BornCow(player, currentId, cowInfoes[currentId].life, cowInfoes[currentId].energy,cowInfoes[currentId].milk,cowInfoes[currentId].milkRate);
        }
        currentId ++;
        _mint(player, tokenId);

        return tokenId;
    }

    function balanceOf(address owner_) external view returns (uint){
        return userInfo[owner_].balances;
    }

    function setStable(address addr) external onlyOwner {
        sta = IStable(addr);
        admin[addr] = true;
    }

    function findIndex(uint[] storage list_, uint tokenId_) internal view returns (uint){
        for (uint i = 0; i < list_.length; i++) {
            if (list_[i] == tokenId_) {
                return i;
            }
        }
        return 1e18;
    }

    function approve(address to, uint256 tokenId) external {
        isApprove[_msgSender()][to][tokenId] = true;
    }

    function costHunger(uint tokenId_, uint amount_) external onlyAdmin {
        cowInfoes[tokenId_].energy -= amount_;
    }

    function _burn(uint tokenId_) internal {
        address temp = ownerOf[tokenId_];
        userInfo[temp].balances --;
        uint index = findIndex(userInfo[temp].cowList, tokenId_);
        require(index < 1e18, 'wrong tokenId');
        uint len = userInfo[temp].cowList.length;
        userInfo[temp].cowList[index] = userInfo[temp].cowList[len - 1];
        userInfo[temp].cowList.pop();
        delete ownerOf[tokenId_];
    }


    function feed(uint tokenId_, uint amount_) external onlyAdmin {
        cowInfoes[tokenId_].energy += amount_;
    }

    function growUp(uint tokenId_, uint amount_) external onlyAdmin {
        cowInfoes[tokenId_].energy -= amount_;
        cowInfoes[tokenId_].growth += amount_ * 10;

        if (cowInfoes[tokenId_].growth >= 300 && !cowInfoes[tokenId_].isAdult) {
            cowInfoes[tokenId_].isAdult = true;
        }
        cowInfoes[tokenId_].checkTime = block.timestamp;
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(cowInfoes[tokenId].isAdult, "can't transfer audlt cattle");
        require(admin[_msgSender()], "not admin");
        if (from != _msgSender()) {
            require(isApprove[from][to][tokenId] || _operatorApprovals[from][_msgSender()], 'Cattle : not approve');
        }
        require(ownerOf[tokenId] == from, 'Cattle : wrong onwer');
        require(!sta.isUsing(tokenId), 'is Using');
        require(!sta.isStable(tokenId), 'in the stable');
        _burn(tokenId);
        ownerOf[tokenId] = to;
        userInfo[to].balances ++;

        userInfo[to].cowList.push(tokenId);
    }

    function burn(uint tokenId_) public returns (bool){
        address tempOwner = ownerOf[tokenId_];
        if (_msgSender() != tempOwner) {
            require(isApprove[tempOwner][_msgSender()][tokenId_] || _operatorApprovals[tempOwner][_msgSender()], 'Cattle : not approve');
        }
        _burn(tokenId_);
        return true;
    }

    function checkUserCowList(address addr_) external view returns (uint[] memory){
        return userInfo[addr_].cowList;
    }

    function _myBaseURI() internal view returns (string memory) {
        return myBaseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}