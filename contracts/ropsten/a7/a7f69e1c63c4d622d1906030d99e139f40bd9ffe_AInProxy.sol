pragma solidity ^0.4.24;

interface Allowed {
    function isAllowed(bytes32 _action, address _user) view external returns(bool);
    function isAllowedUser(address _user) view external returns(bool);
    function adminAddAction(bytes32 _action) external;
}

/// @title AInProxy - defines the cpntracts of AquiferInstitute
/// @author Vincent Serpoul - <vincent@aquiferinstitute.com>
contract AInProxy {

    // update_proxy
    bytes32 public constant ACTION_UPDATE_PROXY = 0x065ff9e9c64f8220e0d82b470342fc090ac9a8fd0a724601f9cce3f6588eb949;

    address public allowedAdd;
    address public aquiferInstituteCoinAdd;
    address public financierParticipationAdd;
    address public bidSubmissionProofsAdd;
    address public rffSessionsAdd;
    address public financingsAdd;

    event AinProxyAddressUpdated(string name, address newAddress);

    modifier addressNotNull(address _address) {
        require(_address != 0, &quot;address is empty&quot;);
        _;
    }

    modifier onlyWhenAllowedToUpdateProxy() {
        require(
            isAllowedToUpdateProxy(msg.sender),
            &quot;sender is not allowed to update proxy addresses&quot;
        );
        _;
    }

    constructor(address _allowed)
    public
    addressNotNull(_allowed)
    {
        allowedAdd = _allowed;
    }

    function isAllowedToUpdateProxy(address _user)
    public
    view
    returns(bool)
    {
        return Allowed(allowedAdd).isAllowed(ACTION_UPDATE_PROXY, _user);
    }

    function setAquiferInstituteCoinAdd(address _aquiferInstituteCoinAdd)
    public
    addressNotNull(_aquiferInstituteCoinAdd)
    onlyWhenAllowedToUpdateProxy()
    {
        aquiferInstituteCoinAdd = _aquiferInstituteCoinAdd;
        emit AinProxyAddressUpdated(&quot;aquiferInstituteCoinAdd&quot;, _aquiferInstituteCoinAdd);
    }

    function setFinancierParticipationAdd(address _financierParticipationAdd)
    public
    addressNotNull(_financierParticipationAdd)
    onlyWhenAllowedToUpdateProxy()
    {
        financierParticipationAdd = _financierParticipationAdd;
        emit AinProxyAddressUpdated(&quot;financierParticipationAdd&quot;, _financierParticipationAdd);
    }

    function setBidSubmissionProofsAdd(address _bidSubmissionProofsAdd)
    public
    addressNotNull(_bidSubmissionProofsAdd)
    onlyWhenAllowedToUpdateProxy()
    {
        bidSubmissionProofsAdd = _bidSubmissionProofsAdd;
        emit AinProxyAddressUpdated(&quot;bidSubmissionProofsAdd&quot;, _bidSubmissionProofsAdd);
    }

    function setRFFSessionsAdd(address _rffSessionsAdd)
    public
    addressNotNull(_rffSessionsAdd)
    onlyWhenAllowedToUpdateProxy()
    {
        rffSessionsAdd = _rffSessionsAdd;
        emit AinProxyAddressUpdated(&quot;rffSessionAdd&quot;, _rffSessionsAdd);
    }

    function setFinancingsAdd(address _financingsAdd)
    public
    addressNotNull(_financingsAdd)
    onlyWhenAllowedToUpdateProxy()
    {
        financingsAdd = _financingsAdd;
        emit AinProxyAddressUpdated(&quot;financingsAdd&quot;, _financingsAdd);
    }

    function setAllowedAdd(address _allowedAdd)
    public
    addressNotNull(_allowedAdd)
    onlyWhenAllowedToUpdateProxy()
    {
        // check if we also are allowed in the new allowed contract
        require(Allowed(_allowedAdd).isAllowed(ACTION_UPDATE_PROXY, msg.sender));
        allowedAdd = _allowedAdd;
        emit AinProxyAddressUpdated(&quot;allowedAdd&quot;, _allowedAdd);
    }

}