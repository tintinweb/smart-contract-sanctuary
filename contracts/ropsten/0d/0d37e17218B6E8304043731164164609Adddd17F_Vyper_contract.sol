# @version ^0.2.11

#from interfaces import ERC1155TokenReceiver
#from interfaces import IERC165
#from interfaces import IERC1155
#from interfaces import IERC1155metadataURI

#implements: IERC165
#implements: IERC1155
#implements: IERC1155metadataURI
#implements: ERC1155TokenReceiver
interface ERC1155TokenReceiver:
    def onERC1155Received(_operator: address, _from: address, _id: uint256, _value: uint256, _data: bytes32) -> Bytes[4]: nonpayable
   
interface Aprobar:
    def isApprovedForAll(account: address, operator: address) -> bool: view

# * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
event TransferSingle:
    operator: indexed(address)
    _from: indexed(address)
    to: indexed(address)
    id: uint256
    value: uint256

# * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
event TranferBatch:
    operator: indexed(address)
    _from: indexed(address)
    to: indexed(address)
    ids: uint256[100]
    values: uint256[100]


# * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to `approved`.
event ApprovalForAll:
    account: indexed(address)
    operator: indexed(address)
    approved: bool

# @dev MUST emit when the URI is updated for a token ID.
# URIs are defined in RFC 3986.
# The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
event URI:
    value: String[100]
    id: indexed(uint256)

_supportedInterfaces: public(HashMap[Bytes[4], bool])
_balances: public(HashMap[uint256, HashMap[address,uint256]])
_operatorApprovals: public(HashMap[address, HashMap[address, bool]])
_copyrights_minteados: public(HashMap[uint256, uint256])

_INTERFACE_ID_ERC165: constant(Bytes[4]) = 0x01ffc9a7
_INTERFACE_ID_ERC1155: constant(Bytes[4]) = 0xd9b67a26
_INTERFACE_ID_ERC1155_METADATA_URI: constant(Bytes[4]) = 0x0e89341c
_ERC1155_ACCEPTED: constant(Bytes[4]) = 0xf23a6e61

name: public(String[40])
symbol: public(String[40])

_uri: constant(String[100]) = 'https://ipfs.io/ipfs/Qmf5aeTsrCsrFWAZ2pjJrbZ3LUFdj4QeQXwioX3veV9fPF?filename=COPYRIGHT.pdf'
_copyright_a_vender: public(HashMap[uint256, uint256])
_costo_por_unidad: constant(decimal) = 0.1
_numero_de_canciones: constant(uint256) = 5

@external
def __init__(_name: String[40], _symbol: String[40]):
    self._supportedInterfaces[_INTERFACE_ID_ERC165] = True
    self._supportedInterfaces[_INTERFACE_ID_ERC1155] = True
    self._supportedInterfaces[_INTERFACE_ID_ERC1155_METADATA_URI] = True
    self.name = _name
    self.symbol = _symbol
    for i in range(0, _numero_de_canciones):
        self._copyright_a_vender[i] = 75



@external
@view
def supportsInterface(interfaceId: Bytes[4]) -> bool:
    return self._supportedInterfaces[interfaceId]

@external
@view
def uri() -> String[100]:
    return _uri

@external
@view
def balanceOf(account: address, id: uint256) -> uint256:
    assert account != ZERO_ADDRESS, "ERC1155: Balance query for the zero address"
    return self._balances[id][account]

#@external
#@view
#def balanceOfBatch(accounts: address[50], ids: uint256[50]) -> uint256[100]:
#    assert len(accounts) == len(ids), "ERC1155: accounts and ids length mismatch"
#    batchBalances: uint256[len(accounts)]

#    for i in accounts:
#        assert i != ZERO_ADDRESS, "ERC1155:"

@external
def setApprovalForAll(operator: address, approved: bool):
    assert msg.sender != operator, 'ERC1155: setting approval status for self'
    self._operatorApprovals[msg.sender][operator] = approved
    log ApprovalForAll(msg.sender, operator, approved)


@external
@view
def isApprovedForAll(account: address, operator: address) -> bool:
    return self._operatorApprovals[account][operator]

@internal
def _doSafeTransferAcceptanceCheck(operator: address, _from: address, to: address, id: uint256, amount: uint256, data: bytes32):

    if to.is_contract:
        assert ERC1155TokenReceiver(to).onERC1155Received(operator, _from, id, amount, data) == _ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received"


@external
def safeTransferFrom(_from: address, to: address, id: uint256, amount: uint256, data: bytes32):
    assert to != ZERO_ADDRESS, "ERC1155: transfer to the zero address"
    assert _from == msg.sender or Aprobar(self).isApprovedForAll(_from, msg.sender), 'ERC1155: Caller is not owner nor approved'
    operator: address = msg.sender
    self._balances[id][_from] -= amount
    self._balances[id][to] += amount
    log TransferSingle(operator, _from, to, id, amount)
    self._doSafeTransferAcceptanceCheck(operator, _from, to, id, amount, data)

@external
@payable
def mint(account: address, id: uint256, amount: uint256, data: bytes32):
    assert msg.value%as_wei_value(_costo_por_unidad, 'ether') == 0, 'Copyright tokens are not fractional'
    assert msg.value == as_wei_value(_costo_por_unidad, 'ether')*amount, 'Insufficient ether to buy that amount'
    assert self._copyrights_minteados[id] + amount <= self._copyright_a_vender[id], 'Insufficient copyright tokens for sell'
    assert account != ZERO_ADDRESS, "ERC1155: mint to the zero address"
    assert id <= (_numero_de_canciones -1)
    operator:address = msg.sender
    self._copyrights_minteados[id] += amount
    self._balances[id][account] += amount
    log TransferSingle(operator,ZERO_ADDRESS, account, id, amount)
    self._doSafeTransferAcceptanceCheck(operator, ZERO_ADDRESS, account, id, amount, data)