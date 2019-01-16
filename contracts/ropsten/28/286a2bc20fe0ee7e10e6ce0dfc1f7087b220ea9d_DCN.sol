pragma solidity ^0.5.0;
contract DCN {
  event SessionUpdated(address user, uint64 exchange_id);
  event PositionUpdated(address user, uint64 exchange_id, uint32 asset_id);
  uint256 creator;
  uint256 exchange_count;
  uint256 asset_count;
  struct Exchange {
    uint64 name;
    uint32 quote_asset_id;
    address owner;
    uint256 fee_balance;
  }
  struct Asset {
    uint32 symbol;
    uint64 unit_scale;
    address contract_address;
  }
  struct User {
    uint256[4294967296] balances;
  }
  struct AssetState {
    int64 quote_qty;
    int64 base_qty;
    uint64 total_deposit;
    uint64 asset_balance;
    int64 min_quote;
    int64 min_base;
    int64 quote_shift;
    int64 base_shift;
    uint64 padding;
    uint64 limit_version;
    uint64 long_max_price;
    uint64 short_min_price;
  }
  struct QuoteAssetState {
    uint64 fee_limit;
    uint64 fee_used;
    uint64 total_deposit;
    uint64 asset_balance;
    uint64 version;
    uint192 unlock_at;
    uint256 padding;
  }
  struct UserExchangeSession {
    AssetState[4294967296] states;
  }
  struct UserSessions {
    UserExchangeSession[4294967296] exchange_sessions;
  }
  Exchange[(2**32)] exchanges;
  Asset[(2**32)] assets;
  User[(2**160)] users;
  UserSessions[(2**160)] sessions;
  
  constructor() public  { assembly { sstore(creator_slot, caller) } }
  
  function get_creator() public view 
  returns (address dcn_creator) { return address(creator); }
  
  function get_asset(uint32 asset_id) public view 
  returns (string memory symbol, uint64 unit_scale, address contract_address) {
    uint256[5] memory return_value_mem;
    assembly {
      let data := sload(add(assets_slot, asset_id))
      mstore(return_value_mem, 96)
      mstore(add(return_value_mem, 96), 4)
      mstore(add(return_value_mem, 128), data)
      mstore(add(return_value_mem, 32), and(div(data, 0x10000000000000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 64), and(data, 0xffffffffffffffffffffffffffffffffffffffff))
      return(return_value_mem, 132)
    }
  }
  
  function get_exchange(uint32 exchange_id) public view 
  returns (string memory name, uint64 quote_asset_id, address addr, uint64 fee_balance) {
    uint256[6] memory return_value_mem;
    assembly {
      let exchange_ptr := add(exchanges_slot, mul(2, exchange_id))
      let exchange_data := sload(exchange_ptr)
      mstore(return_value_mem, 128)
      mstore(add(return_value_mem, 128), 8)
      mstore(add(return_value_mem, 160), exchange_data)
      mstore(add(return_value_mem, 32), and(div(exchange_data, 0x10000000000000000000000000000000000000000), 0xffffffff))
      mstore(add(return_value_mem, 64), and(exchange_data, 0xffffffffffffffffffffffffffffffffffffffff))
      exchange_data := sload(add(exchange_ptr, 1))
      mstore(add(return_value_mem, 96), exchange_data)
      return(return_value_mem, 168)
    }
  }
  
  function get_exchange_count() public view 
  returns (uint32 count) {
    uint256[1] memory return_value_mem;
    assembly {
      let data := sload(exchange_count_slot)
      mstore(return_value_mem, data)
      return(return_value_mem, 32)
    }
  }
  
  function get_asset_count() public view 
  returns (uint32 count) {
    uint256[1] memory return_value_mem;
    assembly {
      let asset_count := sload(asset_count_slot)
      mstore(return_value_mem, asset_count)
      return(return_value_mem, 32)
    }
  }
  
  function get_balance(address user, uint32 asset_id) public view 
  returns (uint256 return_balance) {
    uint256[1] memory return_value_mem;
    assembly {
      let user_ptr := add(users_slot, mul(4294967296, user))
      let balance_ptr := add(user_ptr, asset_id)
      mstore(return_value_mem, sload(balance_ptr))
      return(return_value_mem, 32)
    }
  }
  
  function get_session(address user, uint32 exchange_id) public view 
  returns (uint64 version, uint64 unlock_at, uint64 fee_limit, uint64 fee_used) {
    uint256[4] memory return_value_mem;
    assembly {
      let exchange_ptr := add(exchanges_slot, mul(2, exchange_id))
      let quote_asset_id := and(div(sload(exchange_ptr), 0x10000000000000000000000000000000000000000), 0xffffffff)
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, user)), mul(12884901888, exchange_id))
      let quote_state_ptr := add(session_ptr, mul(3, quote_asset_id))
      let state_data_0 := sload(quote_state_ptr)
      let state_data_1 := sload(add(quote_state_ptr, 1))
      mstore(return_value_mem, and(div(state_data_1, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 32), and(state_data_1, 0xffffffffffffffffffffffffffffffffffffffffffffffff))
      mstore(add(return_value_mem, 64), and(div(state_data_0, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 96), and(div(state_data_0, 0x100000000000000000000000000000000), 0xffffffffffffffff))
      return(return_value_mem, 128)
    }
  }
  
  function get_session_balance(address user, uint32 exchange_id, uint32 asset_id) public view 
  returns (uint64 total_deposit, uint64 asset_balance) {
    uint256[2] memory return_value_mem;
    assembly {
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, user)), mul(12884901888, exchange_id))
      let state_ptr := add(session_ptr, mul(3, asset_id))
      let state_data := sload(state_ptr)
      mstore(return_value_mem, and(div(state_data, 0x10000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 32), and(state_data, 0xffffffffffffffff))
      return(return_value_mem, 64)
    }
  }
  
  function get_session_state(address user, uint32 exchange_id, uint32 asset_id) public view 
  returns (int64 quote_qty, int64 base_qty, int64 quote_shift, int64 base_shift,
           uint64 version, int64 min_quote, int64 min_base, uint64 long_max_price, uint64 short_min_price) {
    uint256[8] memory return_value_mem;
    assembly {
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, user)), mul(12884901888, exchange_id))
      let state_ptr := add(session_ptr, mul(3, asset_id))
      let state_data_0 := sload(state_ptr)
      let state_data_1 := sload(add(state_ptr, 1))
      let state_data_2 := sload(add(state_ptr, 2))
      mstore(return_value_mem, and(div(state_data_0, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 32), and(div(state_data_0, 0x100000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 64), and(div(state_data_1, 0x10000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 96), and(state_data_1, 0xffffffffffffffff))
      mstore(add(return_value_mem, 128), and(div(state_data_2, 0x100000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 160), and(div(state_data_1, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 192), and(div(state_data_1, 0x100000000000000000000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 224), and(div(state_data_2, 0x10000000000000000), 0xffffffffffffffff))
      mstore(add(return_value_mem, 256), and(state_data_2, 0xffffffffffffffff))
      return(return_value_mem, 288)
    }
  }
  
  function set_creator(address new_creator) public  { assembly {
  let current_creator := sload(creator_slot)
  if iszero(eq(current_creator, caller)) { revert(0, 0) }
  sstore(creator_slot, new_creator)
} }
  
  function add_asset(string memory symbol, uint64 unit_scale, address contract_address) public  {
    uint256[1] memory revert_reason;
    assembly {
      let creator_address := sload(creator_slot)
      if iszero(eq(creator_address, caller)) {
        mstore(revert_reason, 1)
        revert(add(revert_reason, 31), 1)
      }
      let asset_id := sload(asset_count_slot)
      if iszero(lt(asset_id, exp(2, 32))) {
        mstore(revert_reason, 2)
        revert(add(revert_reason, 31), 1)
      }
      let symbol_len := mload(symbol)
      if iszero(eq(symbol_len, 4)) {
        mstore(revert_reason, 3)
        revert(add(revert_reason, 31), 1)
      }
      if iszero(unit_scale) {
        mstore(revert_reason, 4)
        revert(add(revert_reason, 31), 1)
      }
      if iszero(contract_address) {
        mstore(revert_reason, 5)
        revert(add(revert_reason, 31), 1)
      }
      let asset_symbol := mload(add(symbol, 32))
      let asset_data := or(asset_symbol, or(
        /* unit_scale */ mul(unit_scale, 0x10000000000000000000000000000000000000000), 
        /* contract_address */ contract_address))
      let asset_ptr := add(assets_slot, asset_id)
      sstore(asset_ptr, asset_data)
      sstore(asset_count_slot, add(asset_id, 1))
    }
  }
  
  function add_exchange(string memory name, uint32 quote_asset_id, address addr) public  {
    uint256[1] memory revert_reason;
    assembly {
      let creator_address := sload(creator_slot)
      if iszero(eq(creator_address, caller)) {
        mstore(revert_reason, 1)
        revert(add(revert_reason, 31), 1)
      }
      let name_len := mload(name)
      if iszero(eq(name_len, 8)) {
        mstore(revert_reason, 2)
        revert(add(revert_reason, 31), 1)
      }
      let asset_count := sload(asset_count_slot)
      if iszero(lt(quote_asset_id, asset_count)) {
        mstore(revert_reason, 3)
        revert(add(revert_reason, 31), 1)
      }
      let exchange_count := sload(exchange_count_slot)
      if iszero(lt(exchange_count, exp(2, 32))) {
        mstore(revert_reason, 4)
        revert(add(revert_reason, 31), 1)
      }
      let exchange_ptr := add(exchanges_slot, mul(2, exchange_count))
      let name_data := mload(add(name, 32))
      let exchange_data := or(name_data, or(
        /* quote_asset_id */ mul(quote_asset_id, 0x10000000000000000000000000000000000000000), 
        /* owner */ addr))
      sstore(exchange_ptr, exchange_data)
      sstore(exchange_count_slot, add(exchange_count, 1))
    }
  }
  
  function deposit_asset(uint32 asset_id, uint256 amount) public  {
    uint256[1] memory revert_reason;
    uint256[4] memory transfer_in_mem;
    uint256[1] memory transfer_out_mem;
    assembly {
      if iszero(amount) { stop() }
      {
        let asset_count := sload(asset_count_slot)
        if iszero(lt(asset_id, asset_count)) {
          mstore(revert_reason, 1)
          revert(add(revert_reason, 31), 1)
        }
      }
      mstore(transfer_in_mem, /* fn_hash("transferFrom(address,address,uint256)") */ 0x23b872dd00000000000000000000000000000000000000000000000000000000)
      mstore(add(transfer_in_mem, 4), caller)
      mstore(add(transfer_in_mem, 36), address)
      mstore(add(transfer_in_mem, 68), amount)
      let asset_data := sload(add(assets_slot, asset_id))
      let asset_address := and(asset_data, 0xffffffffffffffffffffffffffffffffffffffff)
      {
        let success := call(gas, asset_address, 0, transfer_in_mem, 100, transfer_out_mem, 32)
        if iszero(success) {
          mstore(revert_reason, 2)
          revert(add(revert_reason, 31), 1)
        }
        let result := mload(transfer_out_mem)
        if iszero(result) {
          mstore(revert_reason, 3)
          revert(add(revert_reason, 31), 1)
        }
      }
      let user_ptr := add(users_slot, mul(4294967296, caller))
      let asset_ptr := add(user_ptr, asset_id)
      let current_balance := sload(asset_ptr)
      sstore(asset_ptr, add(current_balance, amount))
    }
  }
  
  function withdraw_asset(uint32 asset_id, address destination, uint256 amount) public  {
    uint256[1] memory revert_reason;
    uint256[3] memory transfer_in_mem;
    uint256[1] memory transfer_out_mem;
    assembly {
      if iszero(amount) { stop() }
      let user_ptr := add(users_slot, mul(4294967296, caller))
      let asset_ptr := add(user_ptr, asset_id)
      let current_balance := sload(asset_ptr)
      if lt(current_balance, amount) {
        mstore(revert_reason, 1)
        revert(add(revert_reason, 31), 1)
      }
      mstore(transfer_in_mem, /* fn_hash("transfer(address,uint256)") */ 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
      mstore(add(transfer_in_mem, 4), destination)
      mstore(add(transfer_in_mem, 36), amount)
      let asset_data := sload(add(assets_slot, asset_id))
      let asset_address := and(asset_data, 0xffffffffffffffffffffffffffffffffffffffff)
      let success := call(gas, asset_address, 0, transfer_in_mem, 68, transfer_out_mem, 32)
      if iszero(success) {
        mstore(revert_reason, 2)
        revert(add(revert_reason, 31), 1)
      }
      let result := mload(transfer_out_mem)
      if iszero(result) {
        mstore(revert_reason, 3)
        revert(add(revert_reason, 31), 1)
      }
      sstore(asset_ptr, sub(current_balance, amount))
    }
  }
  
  function update_session(uint32 exchange_id, uint64 unlock_at, uint64 fee_limit) public  {
    uint256[1] memory revert_reason;
    uint256[3] memory log_data_mem;
    assembly {
      if or(lt(unlock_at, add(timestamp, 43200)), gt(unlock_at, add(timestamp, 2592000))) {
        mstore(revert_reason, 1)
        revert(add(revert_reason, 31), 1)
      }
      {
        let exchange_count := sload(exchange_count_slot)
        if iszero(lt(exchange_id, exchange_count)) {
          mstore(revert_reason, 2)
          revert(add(revert_reason, 31), 1)
        }
      }
      let exchange_ptr := add(exchanges_slot, mul(2, exchange_id))
      let quote_asset_id := and(div(sload(exchange_ptr), 0x10000000000000000000000000000000000000000), 0xffffffff)
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, caller)), mul(12884901888, exchange_id))
      let quote_state_ptr := add(session_ptr, mul(3, quote_asset_id))
      let quote_state := sload(quote_state_ptr)
      let current_fee_limit := and(div(quote_state, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
      if lt(fee_limit, current_fee_limit) {
        mstore(revert_reason, 3)
        revert(add(revert_reason, 31), 1)
      }
      if gt(fee_limit, current_fee_limit) { sstore(quote_state_ptr, or(and(quote_state, 0xffffffffffffffffffffffffffffffffffffffffffffffff), 
  /* fee_limit */ mul(fee_limit, 0x1000000000000000000000000000000000000000000000000))) }
      let version := and(div(sload(add(quote_state_ptr, 1)), 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
      sstore(add(quote_state_ptr, 1), or(
        /* version */ mul(add(version, 1), 0x1000000000000000000000000000000000000000000000000), 
        /* unlock_at */ unlock_at))
      
      /* Log event: SessionUpdated */
      mstore(log_data_mem, caller)
      mstore(add(log_data_mem, 32), exchange_id)
      log1(log_data_mem, 64, /* SessionUpdated */ 0x1fceb0227bbc8d151c84f6f90cac5b115842ef0ed5dd5b6ee6bf6eca2dae91f7)
    }
  }
  
  function deposit_asset_to_session(uint32 exchange_id, uint32 asset_id, uint64 quantity) public  {
    uint256[1] memory revert_reason;
    uint256[4] memory transfer_in_mem;
    uint256[1] memory transfer_out_mem;
    uint256[3] memory log_data_mem;
    assembly {
      {
        let asset_count := sload(asset_count_slot)
        if iszero(lt(asset_id, asset_count)) {
          mstore(revert_reason, 1)
          revert(add(revert_reason, 31), 1)
        }
      }
      if iszero(quantity) {
        mstore(revert_reason, 2)
        revert(add(revert_reason, 31), 1)
      }
      let asset_data := sload(add(assets_slot, asset_id))
      let amount := mul(quantity, and(div(asset_data, 0x10000000000000000000000000000000000000000), 0xffffffffffffffff))
      let asset_address := and(asset_data, 0xffffffffffffffffffffffffffffffffffffffff)
      mstore(transfer_in_mem, /* fn_hash("transferFrom(address,address,uint256)") */ 0x23b872dd00000000000000000000000000000000000000000000000000000000)
      mstore(add(transfer_in_mem, 4), caller)
      mstore(add(transfer_in_mem, 36), address)
      mstore(add(transfer_in_mem, 68), amount)
      {
        let success := call(gas, asset_address, 0, transfer_in_mem, 100, transfer_out_mem, 32)
        if iszero(success) {
          mstore(revert_reason, 3)
          revert(add(revert_reason, 31), 1)
        }
        let result := mload(transfer_out_mem)
        if iszero(result) {
          mstore(revert_reason, 4)
          revert(add(revert_reason, 31), 1)
        }
      }
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, caller)), mul(12884901888, exchange_id))
      let asset_state_ptr := add(session_ptr, mul(3, asset_id))
      let asset_state_data := sload(asset_state_ptr)
      let total_deposit := and(add(and(div(asset_state_data, 0x10000000000000000), 0xffffffffffffffff), quantity), 0xFFFFFFFFFFFFFFFF)
      let asset_balance := add(and(asset_state_data, 0xffffffffffffffff), quantity)
      if gt(asset_balance, 0xFFFFFFFFFFFFFFFF) {
        mstore(revert_reason, 5)
        revert(add(revert_reason, 31), 1)
      }
      sstore(asset_state_ptr, or(and(asset_state_data, 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000), or(
        /* total_deposit */ mul(total_deposit, 0x10000000000000000), 
        /* asset_balance */ asset_balance)))
      
      /* Log event: PositionUpdated */
      mstore(log_data_mem, caller)
      mstore(add(log_data_mem, 32), exchange_id)
      mstore(add(log_data_mem, 64), asset_id)
      log1(log_data_mem, 96, /* PositionUpdated */ 0x80e69f6146713abffddddec8ef3901e1cd3fd9e079375d62e04e2719f1adf500)
    }
  }
  
  function transfer_to_session(uint32 exchange_id, uint32 asset_id, uint64 quantity) public  {
    uint256[1] memory revert_reason;
    uint256[4] memory log_data_mem;
    assembly {
      {
        let user_ptr := add(users_slot, mul(4294967296, caller))
        let asset_ptr := add(user_ptr, asset_id)
        let asset_balance := sload(asset_ptr)
        let asset_data := sload(add(assets_slot, asset_id))
        let unit_scale := and(div(asset_data, 0x10000000000000000000000000000000000000000), 0xffffffffffffffff)
        let amount := mul(quantity, unit_scale)
        if gt(amount, asset_balance) {
          mstore(revert_reason, 1)
          revert(add(revert_reason, 31), 1)
        }
        asset_balance := sub(asset_balance, amount)
        sstore(asset_ptr, asset_balance)
      }
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, caller)), mul(12884901888, exchange_id))
      let asset_state_ptr := add(session_ptr, mul(3, asset_id))
      let asset_state_data := sload(asset_state_ptr)
      let total_deposit := add(and(div(asset_state_data, 0x10000000000000000), 0xffffffffffffffff), quantity)
      let asset_balance := add(and(asset_state_data, 0xffffffffffffffff), quantity)
      total_deposit := and(total_deposit, 0xFFFFFFFFFFFFFFFF)
      if gt(asset_balance, 0xFFFFFFFFFFFFFFFF) {
        mstore(revert_reason, 2)
        revert(add(revert_reason, 31), 1)
      }
      sstore(asset_state_ptr, or(and(asset_state_data, 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000), or(
        /* total_deposit */ mul(total_deposit, 0x10000000000000000), 
        /* asset_balance */ asset_balance)))
      
      /* Log event: PositionUpdated */
      mstore(log_data_mem, caller)
      mstore(add(log_data_mem, 32), exchange_id)
      mstore(add(log_data_mem, 64), asset_id)
      log1(log_data_mem, 96, /* PositionUpdated */ 0x80e69f6146713abffddddec8ef3901e1cd3fd9e079375d62e04e2719f1adf500)
    }
  }
  
  function transfer_from_session(uint32 exchange_id, uint32 asset_id, uint64 quantity) public  {
    uint256[1] memory revert_reason;
    uint256[4] memory log_data_mem;
    assembly {
      let exchange_data := sload(add(exchanges_slot, mul(2, exchange_id)))
      let quote_asset_id := and(div(exchange_data, 0x10000000000000000000000000000000000000000), 0xffffffff)
      let session_ptr := add(add(sessions_slot, mul(55340232221128654848, caller)), mul(12884901888, exchange_id))
      {
        let quote_state_ptr := add(session_ptr, mul(3, quote_asset_id))
        let unlock_at := and(sload(add(quote_state_ptr, 1)), 0xffffffffffffffffffffffffffffffffffffffffffffffff)
        if lt(timestamp, unlock_at) {
          mstore(revert_reason, 1)
          revert(add(revert_reason, 31), 1)
        }
      }
      {
        let asset_state_ptr := add(session_ptr, mul(3, asset_id))
        let asset_state_data := sload(asset_state_ptr)
        let asset_balance := and(asset_state_data, 0xffffffffffffffff)
        if gt(quantity, asset_balance) {
          mstore(revert_reason, 2)
          revert(add(revert_reason, 31), 1)
        }
        asset_balance := sub(asset_balance, quantity)
        sstore(asset_state_ptr, or(and(asset_state_data, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000), 
          /* asset_balance */ asset_balance))
      }
      {
        let user_ptr := add(users_slot, mul(4294967296, caller))
        let asset_ptr := add(user_ptr, asset_id)
        let asset_balance := sload(asset_ptr)
        let asset_data := sload(add(assets_slot, asset_id))
        let unit_scale := and(div(asset_data, 0x10000000000000000000000000000000000000000), 0xffffffffffffffff)
        let amount := mul(quantity, unit_scale)
        asset_balance := add(asset_balance, amount)
        if lt(asset_balance, amount) {
          mstore(revert_reason, 3)
          revert(add(revert_reason, 31), 1)
        }
        sstore(asset_ptr, asset_balance)
      }
      
      /* Log event: PositionUpdated */
      mstore(log_data_mem, caller)
      mstore(add(log_data_mem, 32), exchange_id)
      mstore(add(log_data_mem, 64), asset_id)
      log1(log_data_mem, 96, /* PositionUpdated */ 0x80e69f6146713abffddddec8ef3901e1cd3fd9e079375d62e04e2719f1adf500)
    }
  }
  struct Signature {
    uint256 sig_r;
    uint256 sig_s;
    uint8 sig_v;
  }
  struct Address {
    address user_address;
    uint96 padding;
  }
  struct UpdateLimit {
    uint32 exchange_id;
    uint32 asset_id;
    uint64 version;
    uint64 long_max_price;
    uint64 short_min_price;
    uint64 min_quote_qty;
    uint64 min_base_qty;
    uint64 quote_shift;
    uint64 base_shift;
  }
  
  function set_limit(bytes memory data) public  {
    uint256[1] memory revert_reason;
    uint256[10] memory hash_buffer_mem;
    uint256 user_addr;
    assembly {
      let data_size := mload(data)
      let cursor := add(data, 32)
      if iszero(eq(data_size, 149)) {
        mstore(revert_reason, 1)
        revert(add(revert_reason, 31), 1)
      }
      let update_data := mload(cursor)
      cursor := add(cursor, 20)
      user_addr := and(div(update_data, 0x1000000000000000000000000), 0xffffffffffffffffffffffffffffffffffffffff)
      mstore(hash_buffer_mem, 0xe0bfc2789e007df269c9fec46d3ddd4acf88fdf0f76af154da933aab7fb2f2b9)
      update_data := mload(cursor)
      cursor := add(cursor, 32)
      let asset_state_ptr := 0
      {
        let version := 0
        {
          let exchange_id := and(div(update_data, 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)
          mstore(add(hash_buffer_mem, 32), exchange_id)
          let asset_id := and(div(update_data, 0x1000000000000000000000000000000000000000000000000), 0xffffffff)
          mstore(add(hash_buffer_mem, 64), asset_id)
          version := and(div(update_data, 0x100000000000000000000000000000000), 0xffffffffffffffff)
          mstore(add(hash_buffer_mem, 96), version)
          let session_ptr := add(add(sessions_slot, mul(55340232221128654848, user_addr)), mul(12884901888, exchange_id))
          asset_state_ptr := add(session_ptr, mul(3, asset_id))
          {
            let exchange_data := sload(add(exchanges_slot, mul(2, exchange_id)))
            let exchange_address := and(exchange_data, 0xffffffffffffffffffffffffffffffffffffffff)
            if iszero(eq(caller, exchange_address)) {
              mstore(revert_reason, 2)
              revert(add(revert_reason, 31), 1)
            }
            let quote_asset_id := and(div(exchange_data, 0x10000000000000000000000000000000000000000), 0xffffffff)
            if eq(quote_asset_id, asset_id) {
              mstore(revert_reason, 6)
              revert(add(revert_reason, 31), 1)
            }
          }
          let current_version := and(div(sload(add(asset_state_ptr, 2)), 0x100000000000000000000000000000000), 0xffffffffffffffff)
          if iszero(gt(version, current_version)) {
            mstore(revert_reason, 3)
            revert(add(revert_reason, 31), 1)
          }
        }
        {
          let long_max_price := and(div(update_data, 0x10000000000000000), 0xffffffffffffffff)
          mstore(add(hash_buffer_mem, 128), long_max_price)
          let short_min_price := and(update_data, 0xffffffffffffffff)
          mstore(add(hash_buffer_mem, 160), short_min_price)
          sstore(add(asset_state_ptr, 2), or(or(
            /* limit_version */ mul(version, 0x100000000000000000000000000000000), 
            /* long_max_price */ mul(long_max_price, 0x10000000000000000)), 
            /* short_min_price */ short_min_price))
        }
      }
      update_data := mload(cursor)
      cursor := add(cursor, 32)
      let state_data_1 := 0
      {
        let min_quote_qty := and(div(update_data, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
        state_data_1 := 
          /* min_quote */ mul(min_quote_qty, 0x1000000000000000000000000000000000000000000000000)
        if and(min_quote_qty, 0x8000000000000000) { min_quote_qty := or(min_quote_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
        mstore(add(hash_buffer_mem, 192), min_quote_qty)
      }
      {
        let min_base_qty := and(div(update_data, 0x100000000000000000000000000000000), 0xffffffffffffffff)
        state_data_1 := or(state_data_1, 
          /* min_base */ mul(min_base_qty, 0x100000000000000000000000000000000))
        if and(min_base_qty, 0x8000000000000000) { min_base_qty := or(min_base_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
        mstore(add(hash_buffer_mem, 224), min_base_qty)
      }
      let quote_shift := and(div(update_data, 0x10000000000000000), 0xffffffffffffffff)
      state_data_1 := or(state_data_1, 
        /* quote_shift */ mul(quote_shift, 0x10000000000000000))
      if and(quote_shift, 0x8000000000000000) { quote_shift := or(quote_shift, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
      mstore(add(hash_buffer_mem, 256), quote_shift)
      let base_shift := and(update_data, 0xffffffffffffffff)
      state_data_1 := or(state_data_1, 
        /* base_shift */ base_shift)
      if and(base_shift, 0x8000000000000000) { base_shift := or(base_shift, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
      mstore(add(hash_buffer_mem, 288), base_shift)
      sstore(add(asset_state_ptr, 1), state_data_1)
      {
        let current_state_data := sload(add(asset_state_ptr, 1))
        {
          let current_quote_shift := and(div(current_state_data, 0x10000000000000000), 0xffffffffffffffff)
          if and(current_quote_shift, 0x8000000000000000) { current_quote_shift := or(current_quote_shift, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
          quote_shift := sub(quote_shift, current_quote_shift)
        }
        {
          let current_base_shift := and(current_state_data, 0xffffffffffffffff)
          if and(current_base_shift, 0x8000000000000000) { current_base_shift := or(current_base_shift, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
          base_shift := sub(base_shift, current_base_shift)
        }
      }
      let state_data_0 := sload(asset_state_ptr)
      let quote_qty := add(quote_shift, and(div(state_data_0, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff))
      let base_qty := add(base_shift, and(div(state_data_0, 0x100000000000000000000000000000000), 0xffffffffffffffff))
      if or(or(slt(quote_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000), sgt(quote_qty, 0x7fffffffffffffff)), or(slt(base_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000), sgt(base_qty, 0x7fffffffffffffff))) {
        mstore(revert_reason, 4)
        revert(add(revert_reason, 31), 1)
      }
      sstore(asset_state_ptr, or(and(state_data_0, 0xffffffffffffffffffffffffffffffff), or(
        /* min_quote */ mul(and(quote_qty, 0xFFFFFFFFFFFFFFFF), 0x1000000000000000000000000000000000000000000000000), 
        /* min_base */ mul(and(base_qty, 0xFFFFFFFFFFFFFFFF), 0x100000000000000000000000000000000))))
      let hash := keccak256(hash_buffer_mem, 320)
      {
        let final_ptr := hash_buffer_mem
        mstore(final_ptr, 0x1901000000000000000000000000000000000000000000000000000000000000)
        final_ptr := add(final_ptr, 2)
        mstore(final_ptr, 0xe3d3073cc59e3a3126c17585a7e516a048e61a9a1c82144af982d1c194b18710)
        final_ptr := add(final_ptr, 32)
        mstore(final_ptr, hash)
      }
      hash := keccak256(hash_buffer_mem, 66)
      mstore(hash_buffer_mem, hash)
      update_data := mload(cursor)
      cursor := add(cursor, 32)
      mstore(add(hash_buffer_mem, 32), update_data)
      update_data := mload(cursor)
      cursor := add(cursor, 32)
      mstore(add(hash_buffer_mem, 64), update_data)
      update_data := mload(cursor)
      mstore(add(hash_buffer_mem, 96), and(div(update_data, 0x100000000000000000000000000000000000000000000000000000000000000), 0xff))
    }
    uint256 recover_address = uint256(ecrecover(
      bytes32(hash_buffer_mem[0]),
      uint8(hash_buffer_mem[3]),
      bytes32(hash_buffer_mem[1]),
      bytes32(hash_buffer_mem[2])
    ));
    assembly { if iszero(eq(recover_address, user_addr)) {
  mstore(revert_reason, 5)
  revert(add(revert_reason, 31), 1)
} }
  }
  struct GroupsHeader {
    uint32 exchange_id;
  }
  struct GroupHeader {
    uint32 base_asset_id;
    uint8 user_count;
  }
  struct UserAddress {
    address user_address;
  }
  struct Settlement {
    int64 quote_delta;
    int64 base_delta;
    uint64 fees;
  }
  
  function apply_settlement_groups(bytes memory data) public  {
    uint256[5] memory variables;
    assembly {
      let cursor := add(data, 32)
      let data_len := mload(data)
      mstore(sub(msize, 160), add(cursor, data_len))
      if lt(data_len, 4) {
        mstore(sub(msize, 32), 0)
        revert(add(sub(msize, 32), 31), 1)
      }
      let tmp_data := mload(cursor)
      cursor := add(cursor, 4)
      {
        let exchange_id := and(div(tmp_data, 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)
        let exchange_count := sload(exchange_count_slot)
        if iszero(lt(exchange_id, exchange_count)) {
          mstore(sub(msize, 32), 1)
          revert(add(sub(msize, 32), 31), 1)
        }
        let exchange_ptr := add(exchanges_slot, mul(2, exchange_id))
        let exchange_data_0 := sload(exchange_ptr)
        if iszero(eq(caller, and(exchange_data_0, 0xffffffffffffffffffffffffffffffffffffffff))) {
          mstore(sub(msize, 32), 2)
          revert(add(sub(msize, 32), 31), 1)
        }
        mstore(sub(msize, 192), and(div(exchange_data_0, 0x10000000000000000000000000000000000000000), 0xffffffff))
        mstore(sub(msize, 128), sload(add(exchange_ptr, 1)))
        mstore(sub(msize, 96), exchange_id)
      }
      for {} iszero(lt(sub(mload(sub(msize, 160)), cursor), 5)) {} {
        tmp_data := mload(cursor)
        cursor := add(cursor, 5)
        {
          let user_count := and(div(tmp_data, 0x1000000000000000000000000000000000000000000000000000000), 0xff)
          let settlements_size := mul(user_count, 44)
          let group_end := add(cursor, settlements_size)
          if gt(group_end, mload(sub(msize, 160))) {
            mstore(sub(msize, 32), 3)
            revert(add(sub(msize, 32), 31), 1)
          }
          mstore(sub(msize, 64), group_end)
        }
        let base_asset_id := and(div(tmp_data, 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)
        let quote_net := 0
        let base_net := 0
        for {} lt(cursor, mload(sub(msize, 64))) {} {
          tmp_data := mload(cursor)
          cursor := add(cursor, 20)
          let session_ptr := add(add(sessions_slot, mul(55340232221128654848, and(div(tmp_data, 0x1000000000000000000000000), 0xffffffffffffffffffffffffffffffffffffffff))), mul(12884901888, mload(sub(msize, 96))))
          tmp_data := mload(cursor)
          cursor := add(cursor, 24)
          let quote_delta := and(div(tmp_data, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
          let base_delta := and(div(tmp_data, 0x100000000000000000000000000000000), 0xffffffffffffffff)
          let fees := and(div(tmp_data, 0x10000000000000000), 0xffffffffffffffff)
          if and(quote_delta, 0x8000000000000000) { quote_delta := or(quote_delta, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
          if and(base_delta, 0x8000000000000000) { base_delta := or(base_delta, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
          quote_net := add(quote_net, quote_delta)
          base_net := add(base_net, base_delta)
          let quote_state_ptr := add(session_ptr, mul(3, mload(sub(msize, 192))))
          let base_state_ptr := add(session_ptr, mul(3, base_asset_id))
          {
            let state_data_1 := sload(add(quote_state_ptr, 1))
            let unlock_at := and(state_data_1, 0xffffffffffffffffffffffffffffffffffffffffffffffff)
            if gt(timestamp, unlock_at) {
              mstore(sub(msize, 32), 4)
              revert(add(sub(msize, 32), 31), 1)
            }
          }
          {
            let state_data_0 := sload(quote_state_ptr)
            let asset_balance := and(state_data_0, 0xffffffffffffffff)
            asset_balance := add(asset_balance, quote_delta)
            asset_balance := sub(asset_balance, fees)
            if gt(asset_balance, 0xFFFFFFFFFFFFFFFF) {
              mstore(sub(msize, 32), 5)
              revert(add(sub(msize, 32), 31), 1)
            }
            let fee_used := and(div(state_data_0, 0x100000000000000000000000000000000), 0xffffffffffffffff)
            fee_used := add(fee_used, fees)
            let exchange_fees_mem := sub(msize, 128)
            mstore(exchange_fees_mem, add(mload(exchange_fees_mem), fees))
            let fee_limit := and(div(state_data_0, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
            if gt(fee_used, fee_limit) {
              mstore(sub(msize, 32), 6)
              revert(add(sub(msize, 32), 31), 1)
            }
            sstore(quote_state_ptr, or(and(state_data_0, 0xffffffffffffffff0000000000000000ffffffffffffffff0000000000000000), or(
              /* fee_used */ mul(fee_used, 0x100000000000000000000000000000000), 
              /* asset_balance */ asset_balance)))
          }
          let quote_qty := 0
          let base_qty := 0
          {
            let state_ptr := add(session_ptr, mul(3, base_asset_id))
            let state_data_0 := sload(state_ptr)
            let asset_balance := and(state_data_0, 0xffffffffffffffff)
            asset_balance := add(asset_balance, base_delta)
            if gt(asset_balance, 0xFFFFFFFFFFFFFFFF) {
              mstore(sub(msize, 32), 7)
              revert(add(sub(msize, 32), 31), 1)
            }
            quote_qty := and(div(state_data_0, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
            base_qty := and(div(state_data_0, 0x100000000000000000000000000000000), 0xffffffffffffffff)
            if and(quote_qty, 0x8000000000000000) { quote_qty := or(quote_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
            if and(base_qty, 0x8000000000000000) { base_qty := or(base_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
            quote_qty := add(quote_qty, quote_delta)
            base_qty := add(base_qty, base_delta)
            if or(or(slt(quote_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000), sgt(quote_qty, 0x7fffffffffffffff)), or(slt(base_qty, 0xffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000), sgt(base_qty, 0x7fffffffffffffff))) {
              mstore(sub(msize, 32), 8)
              revert(add(sub(msize, 32), 31), 1)
            }
            sstore(state_ptr, or(and(state_data_0, 0xffffffffffffffff0000000000000000), or(or(
              /* quote_qty */ mul(quote_qty, 0x1000000000000000000000000000000000000000000000000), 
              /* base_qty */ mul(base_qty, 0x100000000000000000000000000000000)), 
              /* asset_balance */ asset_balance)))
          }
          {
            let state_data_1 := sload(add(base_state_ptr, 1))
            let min_quote := and(div(state_data_1, 0x1000000000000000000000000000000000000000000000000), 0xffffffffffffffff)
            let min_base := and(div(state_data_1, 0x100000000000000000000000000000000), 0xffffffffffffffff)
            if and(min_quote, 0x8000000000000000) { min_quote := or(min_quote, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
            if and(min_base, 0x8000000000000000) { min_base := or(min_base, 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) }
            if or(slt(quote_qty, min_quote), slt(base_qty, min_base)) {
              mstore(sub(msize, 32), 9)
              revert(add(sub(msize, 32), 31), 1)
            }
          }
          {
            let state_data_2 := sload(add(base_state_ptr, 2))
            let negatives := add(slt(quote_qty, 0), mul(slt(base_qty, 0), 2))
            switch negatives
              case 3 {
                mstore(sub(msize, 32), 10)
                revert(add(sub(msize, 32), 31), 1)
              }
              case 1 {
                if iszero(base_qty) {
                  mstore(sub(msize, 32), 11)
                  revert(add(sub(msize, 32), 31), 1)
                }
                let current_price := div(mul(sub(0, quote_qty), 100000000), base_qty)
                if gt(current_price, and(div(state_data_2, 0x10000000000000000), 0xffffffffffffffff)) {
                  mstore(sub(msize, 32), 12)
                  revert(add(sub(msize, 32), 31), 1)
                }
              }
              case 2 {
                if iszero(quote_qty) {
                  mstore(sub(msize, 32), 13)
                  revert(add(sub(msize, 32), 31), 1)
                }
                let current_price := div(mul(quote_qty, 100000000), sub(0, base_qty))
                if lt(current_price, and(state_data_2, 0xffffffffffffffff)) {
                  mstore(sub(msize, 32), 14)
                  revert(add(sub(msize, 32), 31), 1)
                }
              }
          }
        }
        if or(quote_net, base_net) {
          mstore(sub(msize, 32), 15)
          revert(add(sub(msize, 32), 31), 1)
        }
      }
      let exchange_fees := mload(sub(msize, 128))
      let exchange_id := mload(sub(msize, 96))
      let exchange_ptr := add(exchanges_slot, mul(2, exchange_id))
      sstore(add(exchange_ptr, 1), exchange_fees)
    }
  }
}