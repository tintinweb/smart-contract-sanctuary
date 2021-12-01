/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PaperReviewManager {
  enum ReviewStatus { Unkown, Approved, Rejected }

  event ApprovePaper(bytes20 indexed paper, address indexed reviewer);
  event RejectPaper(bytes20 indexed paper, address indexed reviewer);

  string private greeting;

  mapping(address => mapping(bytes20 => ReviewStatus)) public paperReviews;

  function approve(bytes20 paper) external {
    paperReviews[msg.sender][paper] = ReviewStatus.Approved;
    emit ApprovePaper(paper, msg.sender);
  }

  function reject(bytes20 paper) external {
    paperReviews[msg.sender][paper] = ReviewStatus.Rejected;
    emit RejectPaper(paper, msg.sender);
  }

  function getReview(bytes20 paper, address reviewer) external view returns (ReviewStatus) {
    return paperReviews[reviewer][paper];
  }
}