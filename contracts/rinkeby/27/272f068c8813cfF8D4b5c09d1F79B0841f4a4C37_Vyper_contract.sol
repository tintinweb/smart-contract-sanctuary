# @version >=0.2.7 <0.3.0

owner: address
casings_token_address:address
chainlink_token_address:address
chainlink_vrf_address:address
chainlink_vrf_fee_amount:uint256
revolver_fee_amount:uint256 # Ammunition is paid for with $LINK
randomness_requests_to_results: HashMap[bytes32, uint256]
randomness_requests_to_player: HashMap[bytes32, address]
last_shooter: public(address)
total_casings_issued: public(uint256)

CASINGS_LIMIT: constant(uint256) = 5
BARREL_MODULUS: constant(uint256) = 6

interface CasingsTokenInterface:
    def mint(_to:address, _tokenId:uint256) -> bool : nonpayable

interface ChainlinkRandomInterface:
    def requestRandomness(keyHash:bytes32, fee:uint256) -> bytes32 : nonpayable

interface ChainlinkTokenInterface:
    def allowance(owner:address, spender:address) -> uint256 : view
    def balanceOf(owner:address) -> uint256 : view
    def transfer(sender:address, amount:uint256) -> bool : nonpayable
    def transferFrom(sender:address, recipient:address, amount:uint256) -> bool : nonpayable
    
event TriggerSqueezed:
    linkPaid:uint256
    randomness_request_id:bytes32

event RoundFired:
    outcome: String[32]
    randomness_request_id:bytes32
    randomness:uint256
    barrel_position:uint256

@external
def __init__(chainlink_vrf: address, chainlink_token: address, casings_token: address):
    self.owner = msg.sender
    self.revolver_fee_amount = 1 * 10 ** 18  # 1 LINK token
    self.chainlink_vrf_fee_amount = (1 / 10) * 10 ** 18  # 0.1 LINK tokens
    self.chainlink_vrf_address = chainlink_vrf
    self.chainlink_token_address = chainlink_token
    self.casings_token_address = casings_token
    self.total_casings_issued = 0

@external
def squeeze():
    assert ChainlinkTokenInterface(self.chainlink_token_address).balanceOf(msg.sender) >= self.revolver_fee_amount, "Not enough LINK, sorry bud"
    assert ChainlinkTokenInterface(self.chainlink_token_address).allowance(msg.sender, self) >= self.revolver_fee_amount, "Approval required for LINK token"
    if(ChainlinkTokenInterface(self.chainlink_token_address).transferFrom(msg.sender, self, self.revolver_fee_amount)):
        requestId:bytes32 = ChainlinkRandomInterface(self.chainlink_vrf_address).requestRandomness(keccak256(convert(block.difficulty, bytes32)), self.chainlink_vrf_fee_amount)
        self.randomness_requests_to_results[requestId] = empty(uint256)
        self.randomness_requests_to_player[requestId] = msg.sender
        self.last_shooter = msg.sender
        log TriggerSqueezed(self.revolver_fee_amount, requestId)

@internal
def _dispatch(barrel_position:uint256, shooter:address) -> bool:
    if(barrel_position==0):
        # Nothing happens!
        pass
    elif(barrel_position==1):
        # Half of your Revolver fee is returned to you!
        amount_to_return:uint256 = self.revolver_fee_amount / 2
        ChainlinkTokenInterface(self.chainlink_token_address).transfer(shooter, amount_to_return)
    elif(barrel_position==2):
        # Nothing happens!
        pass
    elif(barrel_position==3):
        # Nothing happens!
        pass
    elif(barrel_position==4):
        # Nothing happens!
        pass
    elif(barrel_position==5):
        # You catch a casing mid-air
        CasingsTokenInterface(self.casings_token_address).mint(shooter, self.total_casings_issued + 1)
        self.total_casings_issued += 1
    return True

@external
def fulfillRandomness(requestId: bytes32, randomness: uint256):
 
    player:address = self.randomness_requests_to_player[requestId]
    self.randomness_requests_to_results[requestId] = randomness
    barrel_position:uint256 = randomness % BARREL_MODULUS
    if(self._dispatch(barrel_position, msg.sender)):
        log RoundFired("Outcome", requestId, randomness, barrel_position)

@external
def collectFees():
    assert msg.sender == self.owner, "Only the owner can collect the fees from the contract"
    send(self.owner, self.balance)
    link_balance:uint256 = ChainlinkTokenInterface(self.chainlink_token_address).balanceOf(self)
    ChainlinkTokenInterface(self.chainlink_token_address).transferFrom(self, self.owner, link_balance)