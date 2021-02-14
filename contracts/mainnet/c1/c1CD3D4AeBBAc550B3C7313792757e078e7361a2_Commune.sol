pragma solidity ^0.7.0;

import "SafeMath.sol";

import 'IERC20.sol';
import 'ICommune.sol';

contract Commune is ICommune {
    using SafeMath for uint256;

    struct aCommune {
        bool allowsJoining;
        bool allowsRemoving;
        bool allowsOutsideContribution;
        address asset;
        uint256 proratedTotal;
        uint256 memberCount;
        address controller;
        string uri;
    }

    mapping (uint256 => aCommune) public getCommune;

    // maybe we should rather use 
    // mapping (address => EnumerableSet.UintSet) private _holderTokens;
    // like https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol#L33
    mapping (uint256 => mapping(address => bool)) private _isCommuneMember;
    
    // commune -> address -> balance
    mapping (uint256 => mapping (address => uint256)) private _balanceAtJoin;

    // commune -> address -> balance 
    mapping (uint256 => mapping (address => uint256)) private _spentBalance;

    // in basis points, 0 through 500, i.e. max take 5%
    uint256 private _feeRate = 100;

    // where fee goes to
    address private _treasuryAddress;

    // for creating new commune IDs
    uint256 private _nonce;

    // can update treasury address and fee rate 
    address private _controllerAddress;


    // Getters /// 

    function numberOfCommunes() external override view returns (uint256){
        return _nonce;
    }

    function isCommuneMember(uint256 commune, address account) external communeExists(commune) override view returns (bool){
        return _isCommuneMember[commune][account];
    }

    function feeRate() external override view returns (uint256){
        return _feeRate;
    }

    function treasuryAddress() external override view returns (address){
        return _treasuryAddress;
    }

    function controller() external override view returns (address){
        return _controllerAddress;
    }
    

    // modifiers 
    modifier controllerOnly(){
        require(msg.sender == _controllerAddress, "Commune: only contract controller can do this");
        _;
    }

    modifier communeControllerOnly(uint256 commune){
        require(getCommune[commune].controller == msg.sender, "Commune: only the commune controller can do this");
        _;
    }

    modifier communeExists(uint256 commune){
        require(commune <= _nonce, "Commune: commune does not exists");
        _;
    }

    function contribute(uint256 amount, uint256 commune) external communeExists(commune) override { 
        require(_isCommuneMember[commune][msg.sender] || getCommune[commune].allowsOutsideContribution, "Commune: Must be a member to contribute");
        require(getCommune[commune].memberCount > 0, "Commune: commune has no members, cannot accept contributions");

        address assetAddress = getCommune[commune].asset;
        IERC20 asset = IERC20(assetAddress);

        uint256 fee = amount
            .mul(_feeRate)
            .div(10000);
        
        uint256 amountToCommune = amount
            .sub(fee)
            .div(getCommune[commune].memberCount);

        asset.transferFrom(msg.sender, address(this), amountToCommune);
        asset.transferFrom(msg.sender, _treasuryAddress, fee);

        getCommune[commune].proratedTotal = getCommune[commune].proratedTotal.add(amountToCommune);

        emit Contribute(msg.sender, commune, amount);
    }

    /**
        @dev _uri should link to a JSON file of the form 
        {
            "title": "Commune Title",
            "description": "Commune description"
        }
    */
    function createCommune(string memory _uri, address asset, bool allowJoining, bool allowRemoving, bool allowOutsideContribution) external override returns(uint256 _id) {  
        require((!allowJoining && allowRemoving) || (allowJoining && !allowRemoving), "Commune: cannot both allow joining and removing");

        _id = ++_nonce;

        getCommune[_id].controller = msg.sender;
        getCommune[_id].allowsJoining = allowJoining;
        getCommune[_id].allowsRemoving = allowRemoving;
        getCommune[_id].allowsOutsideContribution = allowOutsideContribution;
        getCommune[_id].asset = asset;
        getCommune[_id].uri = _uri;

        emit URI(_uri, _id);
    }

    //Join/Add Functions
    function joinCommune(uint256 commune) external override {
        require(getCommune[commune].allowsJoining, "Commune: commune does not allow joining");
        _addCommuneMember(msg.sender, commune);
    }

    function addCommuneMember(address account, uint256 commune) external communeControllerOnly(commune) override {
        _addCommuneMember(account, commune);
    }

    function _addCommuneMember(address account, uint256 commune) private communeExists(commune) {
        require(!_isCommuneMember[commune][account], "Commune: account is already in commune");

        _isCommuneMember[commune][account] = true;
        ++getCommune[commune].memberCount;
        _balanceAtJoin[commune][account] = getCommune[commune].proratedTotal;

        emit AddCommuneMember(account, commune);
    }


    // Leave/Remove Functions
    function leaveCommune(uint256 commune) external override {
        _removeCommuneMember(msg.sender, commune);
    }

    function removeCommuneMember(address account, uint256 commune) external communeControllerOnly(commune) override {
        require(getCommune[commune].allowsRemoving, "Commune: commune does not allow removing");

        _removeCommuneMember(account, commune);
    }

    function _removeCommuneMember(address account, uint256 commune) private communeExists(commune) {
        require(_isCommuneMember[commune][account], "Commune: account is not in commune");

        _isCommuneMember[commune][account] = false;
        getCommune[commune].memberCount = getCommune[commune].memberCount.sub(1);
        // we reset the spent balance, incase they'e added back later, to prevent a negative number 
         _spentBalance[commune][account] = 0;

        emit RemoveCommuneMember(account, commune);
    }



    constructor(address _controller) {
        _setURI("your-uri-here");

        _controllerAddress = _controller;
        _treasuryAddress = _controller;
    }

    /// controller functions ///

    function updateCommuneController(address account, uint256 commune) external communeControllerOnly(commune) override {
        getCommune[commune].controller = account;

        emit UpdateCommuneController(account, commune);
    }

    function updateCommuneURI(string memory _uri, uint256 commune) external communeControllerOnly(commune) override {
        getCommune[commune].uri = _uri;

        emit URI(_uri, commune);
    }

    function updateController(address account) external controllerOnly override {
        _controllerAddress = account;

        emit UpdateController(account);
    }

    function updateFee(uint256 rate) external controllerOnly override {
        // max fee is 5%
        require(rate <= 500 && rate >= 0, "Commune: fee rate must be between 0 and 500");
        _feeRate = rate;

        emit UpdateFee(rate);
    }

    function setTreasuryAddress(address newTreasury) external controllerOnly override {
        _treasuryAddress = newTreasury;

        emit UpdateTreasuryAddress(newTreasury);
    }

    // boiler, mostly ripped from ERC1155 then modified

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    string private _uri;
    
    function uri(uint256 commune) communeExists(commune) external view  returns (string memory) {

        string memory _communeURI = getCommune[commune].uri;

        // if the commune URI is set, return it. Note, might still need to replace `\{id\}`
        if (bytes(_communeURI).length > 0) {
            return _communeURI;
        } 

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return _uri;
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function balanceOf(address account, uint256 commune) public view virtual override returns (uint256) {
        require(account != address(0), "Commune: balance query for the zero address");
        if(!_isCommuneMember[commune][account]){
            return 0;
        }
        return getCommune[commune].proratedTotal
            .sub(_balanceAtJoin[commune][account])
            .sub(_spentBalance[commune][account]);
    }

    /**
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "Commune: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "Commune: batch balance query for the zero address");
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }


    function setApprovalForAll(address operator, bool approved) public virtual {
        require(msg.sender != operator, "Commune: setting approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }


    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function withdraw(address account, address to, uint256 commune, uint256 amount) public override {
        require(to != address(0), "Commune: Cannot withdraw to the zero address");
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "Commune: Caller is not owner nor approved"
        );

        address operator = msg.sender;

        balanceOf(account, commune).sub(amount, "Commune: withdraw amount exceeds balance");
        _spentBalance[commune][account] = _spentBalance[commune][account].add(amount);

        IERC20(getCommune[commune].asset).transfer(to, amount);

        emit Withdraw(operator, account, to, commune, amount);
    }

    function withdrawBatch(address account, address to, uint256[] memory communes, uint256[] memory amounts) public override {
        require(to != address(0), "Commune: Cannot withdraw to the zero address");
        require(
            account == msg.sender || isApprovedForAll(account, msg.sender),
            "Commune: Caller is not owner nor approved"
        );

        address operator = msg.sender;

        for (uint i = 0; i < communes.length; i++) {
            balanceOf(account, communes[i]).sub(amounts[i], "Commune: withdraw amount exceeds balance");
            _spentBalance[communes[i]][account] = _spentBalance[communes[i]][account].add(amounts[i]);
            IERC20(getCommune[communes[i]].asset).transfer(to, amounts[i]);
        }

        emit WithdrawBatch(operator, account, to, communes, amounts);
    }
    
}