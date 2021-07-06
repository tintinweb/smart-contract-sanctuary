pragma solidity ^0.7.0;
pragma experimental SMTChecker;

//SPDX-License-Identifier: MIT
import "./Claimable.sol";
import "./ccToken.sol";
import "./BlockedList.sol";
import "./ccTokenControllerIf.sol";
import "./MemberMgrIf.sol";
import "./MintFactory.sol";
import "./CanReclaimToken.sol";

/// @title ccTokenController
contract ccTokenController is ccTokenControllerIf, Claimable, BlockedList, CanReclaimToken {
    ccToken public token;
    MemberMgrIf public members;
    address public factory;

    function getToken() view override external returns (ERC20If){
        return token;
    }

    function requireCustodian(address _who) override public view {
        members.requireCustodian(_who);
    }

    function requireMerchant(address _who) override public view {
        members.requireMerchant(_who);
    }

    event MembersSet(MemberMgrIf indexed members);

    function setMembers(MemberMgrIf _members) external onlyOwner returns (bool) {
        require((address)(_members) != address(0), "invalid _members address");
        members = _members;
        emit MembersSet(members);
        return true;
    }

    event FactorySet(address indexed factory);

    function setFactory(address _factory) external onlyOwner returns (bool) {
        require(_factory != address(0), "invalid _factory address");
        factory = _factory;
        emit FactorySet(factory);
        return true;
    }

    event Paused(bool indexed status);

    bool public _paused = false;

    constructor(ccToken _token){
        token = _token;
        factory = (address)(new MintFactory());
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "sender not authorized for minting or burning.");
        _;
    }

    function transferOwnershipOfOwned(address _newOwner, Ownable owned) public onlyOwner {
        owned.transferOwnership(_newOwner);
    }

    function reclaimTokenOfOwned(ERC20If _token, CanReclaimToken owned) external onlyOwner {
        owned.reclaimToken(_token);
    }

    function claimOwnershipOfToken() public onlyOwner {
        token.claimOwnership();
        token.setController((ERC20ControllerViewIf)(this));
    }

    function paused() override public view returns (bool){
        return _paused;
    }

    function setPaused(bool status) public onlyOwner {
        _paused = status;
        emit Paused(status);
    }

    // only factory actions on token
    function mint(address to, uint amount) override external onlyFactory returns (bool) {
        require(to != address(0), "invalid to address");
        require(!paused(), "paused.");
        require(token.mint(to, amount), "minting failed.");
        return true;
    }

    function burn(uint value) override external onlyFactory returns (bool) {
        require(!paused(), "token is paused.");
        require(token.burn(value));
        return true;
    }

    function burnBlocked(address addrBlocked, uint256 amount) public onlyOwner returns (bool){
        require(token.burnBlocked(addrBlocked,amount), "burnBlocked failed");
        return true;
    }

}