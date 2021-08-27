/**
 *Submitted for verification at Etherscan.io on 2021-08-27
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
    function submissionCounter() external view returns (uint256);
}

/**
 * @title ERC20 Interface
 * @dev See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol.
 */
interface IERC20 {
    function balanceOf(address _human) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

/**
 *  @title UBIProxy
 *  A proxy contract for UBI that implements a token interface to interact with other dapps.
 *  Note that it isn't an ERC20 and only implements its interface in order to be compatible with Snapshot.
 */
contract UBIProxy {
    IProofOfHumanity public PoH;
    IERC20 public UBI;
    address public governor = msg.sender;
    string public name = "UBI Vote";
    string public symbol = "UBIVOTE";
    uint8 public decimals = 18;

    /** @dev Constructor.
     *  @param _PoH The address of the related ProofOfHumanity contract.
     *  @param _UBI The address of the related UBI contract.
     */
    constructor(IProofOfHumanity _PoH, IERC20 _UBI) public {
        PoH = _PoH;
        UBI = _UBI;
    }

    /** @dev Changes the address of the the related ProofOfHumanity contract.
     *  @param _PoH The address of the new contract.
     */
    function changePoH(IProofOfHumanity _PoH) external {
        require(msg.sender == governor, "The caller must be the governor.");
        PoH = _PoH;
    }

    /** @dev Changes the address of the the related UBI contract.
     *  @param _UBI The address of the new contract.
     */
    function changeUBI(IERC20 _UBI) external {
        require(msg.sender == governor, "The caller must be the governor.");
        UBI = _UBI;
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

    /**
     * @dev Calculates the square root of a number. Uses the Babylonian Method.
     * @param x The input.
     * @return y The square root of the input.
     **/
    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // ******************** //
    // *      IERC20      * //
    // ******************** //

    /** @dev Returns the square root of the UBI balance of a particular submission of the ProofOfHumanity contract.
     *  Note that this function takes the expiration date into account.
     *  @param _submissionID The address of the submission.
     *  @return The balance of the submission.
     */
    function balanceOf(address _submissionID) external view returns (uint256) {
        return
            isRegistered(_submissionID)
                ? sqrt(UBI.balanceOf(_submissionID))
                : 0;
    }

    /** @dev Returns the total supply of the UBI token.
     *  This function should really count the square root of each humans balance, but this would be costly.
     *  @return The total supply.
     */
    function totalSupply() external view returns (uint256) {
        return UBI.totalSupply();
    }

    function transfer(address _recipient, uint256 _amount)
        external
        returns (bool)
    {
        return false;
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {}

    function approve(address _spender, uint256 _amount)
        external
        returns (bool)
    {
        return false;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        return false;
    }
}