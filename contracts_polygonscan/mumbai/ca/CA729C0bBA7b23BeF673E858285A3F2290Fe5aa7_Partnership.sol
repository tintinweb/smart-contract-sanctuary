/**
 *Submitted for verification at polygonscan.com on 2021-11-07
*/

// SPDX-License-Identifier: GPL-v3-only
pragma solidity ^0.8.0;




// File: contracts/Storage.sol



/**
* @title FreeTokenWorld Storage
*/
contract Storage {
    bool initialized;

    address internal _owner;

    string public name;
    string public symbol;

    uint public nextProjectId;

    struct Project {
        uint id;
        address contractAddress;
        address[] partners;
        uint[] partition;
        uint totalIncome;
    }

    Project[] public projects;
    
    /// projectId => partner => received value
    mapping(uint => mapping(address => uint)) public incomes;
    /// account => has admin right
    mapping(address => bool) public admins;
    

}

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

// File: contracts/Ownable.sol




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
abstract contract Ownable is Context, Storage {
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _isOwner() internal view returns (bool) {
        return owner() == _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_isOwner(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "the new owner can't be the zero address");
        _setOwner(_newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        admins[newOwner] = true;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

     /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    
}

// File: @openzeppelin/contracts/utils/Address.sol



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/Partnership.sol

/**
* @title Partnership
*/
contract Partnership is Ownable {
    using Address for address payable;

    function init(address _admin) external {
        require(!initialized, 'contract is already initialized');
        nextProjectId=1;
        name = 'Partnership';
        symbol = 'PARTNER';
        _setOwner(_admin);
    }


    modifier onlyAdmin {
        require(admins[_msgSender()], 'denied : reserved to admin');
        _;
    }


    modifier validPartnership(address[] memory partners, uint[] memory partition) {
        require(partners.length == partition.length, 'each partner must have its corresponding indexed partition');
        uint sum;
        for (uint i = 0; i < partners.length; i++) {
            sum += partition[i];
        }
        require(sum == 100, 'the sum of partition iterations must equal 100');
        _;
    }

    function supportsPartnership() external pure returns (bool supported) {
        supported = true;
    }


    function grantOrRevokeAdminRight(address _admin, bool _granted) public onlyOwner {    
        admins[_admin] = _granted;
    }


    function _projectIndex(uint projectId) internal view returns(uint pIndex) {
        for (uint i = 0; i < projects.length; i++) {
            if (projects[i].id == projectId)
                return i;
        }
    }


    function createProject(
        address contractAddress, 
        address[] memory partners, 
        uint[] memory partition
    ) public onlyAdmin validPartnership(partners, partition)
    returns(uint createdProjectId) {
        uint projectId = nextProjectId;
        nextProjectId++;
        projects.push(
            Project(
                projectId,
                contractAddress,
                partners,
                partition,
                0
            )
        );
        return projectId;
    }

    

    function updateProjectPartners(
        uint projectId, 
        address[] memory partners, 
        uint[] memory partition
    ) public onlyAdmin validPartnership(partners, partition) 
    returns(bool updated) {
        uint pIndex = _projectIndex(projectId);
        projects[pIndex].partners = partners;
        projects[pIndex].partition = partition;
        return true;
    }

    function updateProjectContractAddress(uint projectId, address newAddress) public onlyAdmin returns(bool updated) {
        uint pIndex = _projectIndex(projectId);
        projects[pIndex].contractAddress = newAddress;
        return true;
    }

    function projectIndexFromAddress(address projectAddress) public view returns(uint) {
        uint len = projects.length;
        uint projectIndex = len;

        for (uint i = 0; i < len; i++) {
            if (address(projects[i].contractAddress) == address(projectAddress)) {
                projectIndex = i;
            }
        }

        require(projectIndex < len, 'valueReceiver Error : can not find related project');

        return projectIndex;
    }

    function valueReceiver() external payable returns (bool received){
        uint value = msg.value;
        require(value > 0, 'value must be greater than zero');
        address sender = _msgSender();
        uint projectIndex = projectIndexFromAddress(sender);

        Project memory project = projects[projectIndex];

        projects[projectIndex].totalIncome = projects[projectIndex].totalIncome + value;
        
        uint unit = value / 100;

        uint available = value;
        uint len = project.partners.length;

        for (uint p = 0; p < len; p++) {
            address partner = project.partners[p];
            uint pPart = project.partition[p] * unit;
            
            if (p == (len - 1)) {
                pPart = (
                    (available - pPart) > 0
                    ? available
                    : pPart
                );
            }

            incomes[project.id][partner] = incomes[project.id][partner] + pPart;

            payable(partner).sendValue(pPart);

            available-=pPart;

            // project.partners[p]
        }

        require(available == 0, 'no remaining value');

        return true;
    }

    function getProject(uint projectId) public view returns(Project memory project) {
        project = projects[_projectIndex(projectId)];
    }

    function getProjectFromAddress(address projectAddress) public view returns(Project memory project) {
        project = projects[projectIndexFromAddress(projectAddress)];
    }

    function totalPartnerIncome(address partner, uint projectId) public view returns(uint tIncome) {
        if (projectId == 0) {
            // get the total on all projects
            for (uint i = 0; i < projects.length; i++) {
                tIncome += incomes[projects[i].id][partner];
            }
        }
        else {
            // get the total of one project
            tIncome = incomes[projectId][partner];
        }
    }

}