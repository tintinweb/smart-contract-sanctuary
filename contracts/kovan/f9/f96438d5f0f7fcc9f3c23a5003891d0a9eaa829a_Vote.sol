/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Vote{
    struct candidate{
        uint8 index;
        bool bool_voted;
    }

    uint32[] public vote_variants;

    mapping(address => candidate) public map_of_candidates;

    // добавляем элементы, за которые будем голосовать
    function AddVariantVote(uint32 new_element) public {
        return vote_variants.push(new_element);
    }

    // описываем события
    event VotedYes(uint8 index);
    event VotedNo(uint8 index);

    // записываем голос
    function AddVote(uint8 index) public {

        // если запись false, то вызываем событие не голосовать 
        if (map_of_candidates[msg.sender].bool_voted) {
            emit VotedNo(index);
        }
        require(map_of_candidates[msg.sender].bool_voted == false, "You've already voted!");

        // если из функции не выкинуло вышенаписанными операторами, то выполняем следующее
        // флаги фиксируют, что кандидат проголосовал
        map_of_candidates[msg.sender].bool_voted = true;
        map_of_candidates[msg.sender].index = index;
        ++vote_variants[index];
        emit VotedYes(index);
    }

    // удаляем голос
    function DeleteVote() public {
        // отрабатываем исключения - вызываем функцию лишь в том случае, если не проголовали
        require(map_of_candidates[msg.sender].bool_voted == true, "You havent't voted yet!");
        map_of_candidates[msg.sender].bool_voted = true;
        --vote_variants[map_of_candidates[msg.sender].index];
    }

    // возврат флага голосования
    function GetBoolVoted() public view returns(bool) {
        return map_of_candidates[msg.sender].bool_voted;
    }

    // возврат того кто голосует
    function GetIndex() public view returns(uint8) {
        return map_of_candidates[msg.sender].index;
    }

}