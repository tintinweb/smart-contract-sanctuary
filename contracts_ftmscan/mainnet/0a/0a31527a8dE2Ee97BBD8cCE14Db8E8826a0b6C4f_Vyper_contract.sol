# @version 0.3.0


interface AnyCallProxy:
    def encode(_sig: String[64], _data: Bytes[64]) -> ByteArray: pure


event AdminUpdated:
    _from_chain_id: indexed(uint256)
    _idx: indexed(uint256)
    _old_admin: address
    _new_admin: address


struct ByteArray:
    offset: uint256
    length: uint256
    data: uint256[2]


ANYCALL_PROXY: constant(address) = 0xd50aB2485E20103fbd0a7E8C09230bFbef6D4e90
PROXY_ADMIN: constant(address) = 0x35479295F0AB22ec8C0D242e626f48A4A2864CCE


# chain id -> admins[2]
admins: public(HashMap[uint256, address[2]])


@external
def fetch_admin(_chain_id: uint256, _idx: uint256):
    """
    @notice Issue a cross chain call fetching the address of an admin in the proxy admin set
    @dev The result of the call will be supplied in the callback function
    """
    raw_call(
        ANYCALL_PROXY,
        _abi_encode(
            convert(160, uint256),  # to address[] offset - 0
            convert(224, uint256),  # data bytes[] offset - 1
            convert(384, uint256),  # callbacks address[] offset - 2
            convert(448, uint256),  # nonces uint256[] offset - 3
            _chain_id,  # toChainID uint256 - 4
            convert(1, uint256),  # to address[] length - 5
            PROXY_ADMIN,  # to address element - 6
            convert(1, uint256),  # data bytes[] length - 7
            convert(32, uint256),  # offset of bytes element - 8
            convert(36, uint256),  # length of bytes element - 9
            AnyCallProxy(ANYCALL_PROXY).encode("admins(uint256)", _abi_encode(_idx)).data,  # bytes element - 10/11
            convert(1, uint256),  # callbacks address[] length - 12
            self,  # address element - 13
            convert(1, uint256),  # nonces uint256[] length - 14
            convert(0, uint256),  # uint256 element - 15
            method_id=method_id("anyCall(address[],bytes[],address[],uint256[],uint256)"),
        )
    )


@external
def callback(_to: address, _data: Bytes[256], _nonces: uint256, _from_chain_id: uint256, _success: bool, _result: Bytes[256]):
    assert msg.sender == ANYCALL_PROXY  # dev: invalid caller
    assert _to == PROXY_ADMIN  # dev: invalid to address
    assert _success  # dev: unsuccessful

    idx: uint256 = convert(extract32(_data, 4), uint256)
    admin: address = extract32(_result, 0, output_type=address)

    log AdminUpdated(_from_chain_id, idx, self.admins[_from_chain_id][idx], admin)
    self.admins[_from_chain_id][idx] = admin