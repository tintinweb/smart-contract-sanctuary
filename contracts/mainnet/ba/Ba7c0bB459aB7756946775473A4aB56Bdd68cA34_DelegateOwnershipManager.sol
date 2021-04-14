// SPDX-License-Identifier: UNLICENSED
// This code is the property of the Aardbanq DAO.
// The Aardbanq DAO is located at 0x829c094f5034099E91AB1d553828F8A765a3DaA1 on the Ethereum Main Net.
// It is the author's wish that this code should be open sourced under the MIT license, but the final 
// decision on this would be taken by the Aardbanq DAO with a vote once sufficient ABQ tokens have been 
// distributed.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity >=0.7.0;
import "./Minter.sol";
import "./AbqErc20.sol";

/// @notice A delegate ownership manager to allow minting permissions to be set independent of ownership on the ABQ token.
contract DelegateOwnershipManager is Minter
{
    /// @notice The ABQ token.
    AbqErc20 public abqToken;
    /// @notice The owner of the DelegateOwnershipManager. This should be the Aardbanq DAO.
    address public owner;
    /// @notice The addresses that have mint permissions.
    mapping(address => bool) public mintPermission;

    modifier onlyOwner()
    {
        require(msg.sender == owner, "ABQ/only-owner");
        _;
    }

    modifier onlyOwnerOrMintPermission()
    {
        require(msg.sender == owner || mintPermission[msg.sender], "ABQ/only-owner-or-mint-permission");
        _;
    }

    /// @notice Construct a DelegateOwnershipManager.
    /// @param _abqToken The ABQ token.
    /// @param _owner The owner for this contract. This should be the Aardbanq DAO.
    constructor (AbqErc20 _abqToken, address _owner)
    {
        abqToken = _abqToken;
        owner = _owner;
    }

    /// @notice Event emitted when minting permission is set.
    /// @param target The address to set permission for.
    /// @param mayMint The permission state.
    event MintPermission(address indexed target, bool mayMint);
    /// @notice Set minting permission for a given address.
    /// @param _target The address to set minting permission for.
    /// @param _mayMint If set to true the _target address will be allowed to mint.
    function setMintPermission(address _target, bool _mayMint)
        onlyOwner()
        external
    {
        mintPermission[_target] = _mayMint;
        emit MintPermission(_target, _mayMint);
    }

    /// @notice The event emitted if the owner is changed.
    /// @param newOwner The new owner for this contract.
    event OwnerChange(address indexed newOwner);
    /// @notice Allows the owner to change the ownership to another address.
    /// @param _newOwner The address that should be the new owner.
    function changeThisOwner(address _newOwner)
        external
        onlyOwner()
    {
        owner = _newOwner;
        emit OwnerChange(_newOwner);
    }

    /// @notice Mint tokens should the msg.sender has permission to mint.
    /// @param _target The address to mint tokens to.
    /// @param _amount The amount of tokens to mint.
    function mint(address _target, uint256 _amount)
        onlyOwnerOrMintPermission()
        override
        external
    {
        abqToken.mint(_target, _amount);
    }

    /// @notice Change the owner of the token. Only the owner may call this.
    /// @param _newOwner The new owner of the token.
    function changeTokenOwner(address _newOwner)
        onlyOwner()
        external
    {
        abqToken.changeOwner(_newOwner);
    }

    /// @notice Change the name of the token. Only the owner may call this.
    function changeName(string calldata _newName)
        onlyOwner()
        external
    {
        abqToken.changeName(_newName);
    }

    /// @notice Change the symbol of the token. Only the owner may call this.
    function changeSymbol(string calldata _newSymbol)
        onlyOwner()
        external
    {
        abqToken.changeSymbol(_newSymbol);
    }
}