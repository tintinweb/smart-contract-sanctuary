/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

/**
 *  @authors: [@unknownunknown1*, @clesaege]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 *  @tools: []
 */

pragma solidity ^0.5.17;

interface IProofOfHumanity {
    
    /** @dev Return true if the submission is registered and not expired.
     *  @param _submissionID The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) external view returns (bool);
    
    /** @dev Return the number of submissions irrespective of their status.
     *  @return The number of submissions.
     */
    function submissionCounter() external view returns (uint);
    
}

/**
 *  @title ProofOfHumanityProxy
 *  A proxy contract for ProofOfHumanity that implements a token interface to interact with other dapps.
 *  Note that it isn't an ERC20 and only implements its interface in order to be compatible with Snapshot.
 */
contract ProofOfHumanityProxy {

    IProofOfHumanity public PoH;
    address public governor = msg.sender;
    string public name = "Human Vote";
    string public symbol = "VOTE";
    uint8 public decimals = 0;

    /** @dev Constructor.
     *  @param _PoH The address of the related ProofOfHumanity contract.
     */
    constructor(IProofOfHumanity _PoH) public {
        PoH = _PoH;
    }

    /** @dev Changes the address of the the related ProofOfHumanity contract.
     *  @param _PoH The address of the new contract.
     */
    function changePoH(IProofOfHumanity _PoH) external {
        require(msg.sender == governor, "The caller must be the governor.");
        PoH = _PoH;
    }
    
    /** @dev Changes the address of the the governor.
     *  @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external {
        require(msg.sender == governor, "The caller must be the governor.");
        governor = _governor;
    }
    

    /** @dev Returns true if the submission is registered and not expired.
     *  @param _submissionID The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) public view returns (bool) {
        return PoH.isRegistered(_submissionID);
    }

    // ******************** //
    // *      IERC20      * //
    // ******************** //

    /** @dev Returns the balance of a particular submission of the ProofOfHumanity contract.
     *  Note that this function takes the expiration date into account.
     *  @param _submissionID The address of the submission.
     *  @return The balance of the submission.
     */
    function balanceOf(address _submissionID) external view returns (uint256) {
        return isRegistered(_submissionID) ? 1 : 0;
    }

    /** @dev Returns the count of all submissions that made a registration request at some point, including those that were added manually.
     *  Note that with the current implementation of ProofOfHumanity it'd be very costly to count only the submissions that are currently registered.
     *  @return The total count of submissions.
     */
    function totalSupply() external view returns (uint256) {
        return PoH.submissionCounter();
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) { return false; }

    function allowance(address _owner, address _spender) external view returns (uint256) {}

    function approve(address _spender, uint256 _amount) external returns (bool) { return false; }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) { return false; }
}