import '../models/standing_order.dart';

/// Comprehensive reference catalogue of UK Parliamentary Standing Orders
/// (House of Commons & House of Lords).
abstract class StandingOrdersData {
  static const List<StandingOrder> allOrders = [
    // ─── House of Commons ──────────────────────────────────────────────────
    StandingOrder(
      id: 'commons-1',
      house: 'Commons',
      number: '1',
      title: 'Sittings of the House',
      category: 'Sittings & Adjournment',
      summary:
          '(1) The House shall meet on Mondays at 2.30 pm, on Tuesdays and Wednesdays at 11.30 am, on Thursdays at 9.30 am and on Fridays at 9.30 am.\n(2) Prayers shall be read at the commencement of each sitting.\n(3) At 10.00 pm on Mondays, 7.00 pm on Tuesdays and Wednesdays, 5.00 pm on Thursdays and 2.30 pm on Fridays, the Speaker shall interrupt the business under consideration, and if the House be in committee the occupant of the Chair shall leave the Chair and report progress and ask leave to sit again.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4574/sittings-of-the-house/',
    ),
    StandingOrder(
      id: 'commons-9',
      house: 'Commons',
      number: '9',
      title: 'Sittings of the House (10 pm Rule)',
      category: 'Sittings & Adjournment',
      summary:
          '(1) Except as otherwise provided in these Standing Orders, at the moment of interruption of business, the proceedings then under consideration shall stand adjourned.\n(2) If the House be in committee, the Chair shall leave the Chair and report progress and ask leave to sit again.\n(3) After the business under consideration has been disposed of, no opposed business shall be taken.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4580/interruption-of-business/',
    ),
    StandingOrder(
      id: 'commons-10',
      house: 'Commons',
      number: '10',
      title: 'Westminster Hall sittings',
      category: 'Sittings & Adjournment',
      summary:
          '(1) Sittings of the House in Westminster Hall shall take place on Mondays at 4.30 pm, on Tuesdays and Wednesdays at 9.30 am and 2.30 pm, and on Thursdays at 1.30 pm.\n(2) Any Member of the House may take part in a sitting in Westminster Hall.\n(3) The business taken at any sitting in Westminster Hall shall be determined by the Chairman of Ways and Means in accordance with guidelines agreed by the Liaison Committee.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4585/westminster-hall-sittings/',
    ),
    StandingOrder(
      id: 'commons-14',
      house: 'Commons',
      number: '14',
      title: 'Arrangement of public business',
      category: 'Public Business',
      summary:
          '(1) Save as provided in this order, government business shall have precedence at every sitting.\n(2) Twenty days shall be allotted in each session for the consideration of opposition business, of which seventeen days shall be at the disposal of the leader of the largest opposition party and three days at the disposal of the leader of the second largest opposition party.\n(3) Thirty-five days shall be allotted in each session for the consideration of backbench business.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4590/arrangement-of-public-business/',
    ),
    StandingOrder(
      id: 'commons-22',
      house: 'Commons',
      number: '22',
      title: 'Notices of questions, motions and amendments',
      category: 'Public Business',
      summary:
          '(1) Notices of questions, motions and amendments shall be given to the Clerks at the Table or submitted electronically in such form and by such time as the Speaker may direct.\n(2) No notice of a question, motion or amendment shall be printed or circulated if in the opinion of the Speaker it contains improper or unparliamentary language.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4600/notices-of-questions-motions-and-amendments/',
    ),
    StandingOrder(
      id: 'commons-24',
      house: 'Commons',
      number: '24',
      title: 'Emergency debates',
      category: 'Debate & Order',
      summary:
          '(1) On any day on which the House sits, a Member rising in his or her place after questions may propose that the House do now adjourn for the purpose of discussing a specific and important matter that should have urgent consideration.\n(2) The Member making the application shall make a statement not exceeding three minutes, and the Speaker shall decide whether the application shall be granted.\n(3) If the Speaker grants the application and forty Members rise in their places to support it, the debate shall stand over until 3.30 pm on the same day or 9.30 am on the following sitting day as the Speaker may direct.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4605/emergency-debates/',
    ),
    StandingOrder(
      id: 'commons-29',
      house: 'Commons',
      number: '29',
      title: 'Motions for adjournment of the House',
      category: 'Sittings & Adjournment',
      summary:
          '(1) No motion for the adjournment of the House shall be made on any day before the moment of interruption except by a Minister of the Crown.\n(2) At the conclusion of the sitting after the interruption of business, a motion "That this House do now adjourn" may be moved by a Minister of the Crown to enable a backbench Member to initiate an adjournment debate lasting not more than thirty minutes.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4610/motions-for-adjournment/',
    ),
    StandingOrder(
      id: 'commons-36',
      house: 'Commons',
      number: '36',
      title: 'Closure of debate',
      category: 'Debate & Order',
      summary:
          '(1) After a question has been proposed a Member rising in his or her place may claim to move, "That the question be now put," and, unless it shall appear to the Chair that such motion is an abuse of the rules of the House, or an infringement of the rights of the minority, the question, "That the question be now put," shall be put forthwith.\n(2) When a motion "That the question be now put" has been carried, and the question consequent thereon has been decided, any further motion may be made which may be requisite to bring to a decision any question already proposed from the Chair.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4620/closure-of-debate/',
    ),
    StandingOrder(
      id: 'commons-37',
      house: 'Commons',
      number: '37',
      title: 'Majority for closure',
      category: 'Debate & Order',
      summary:
          'A motion for the closure of debate under Standing Order No. 36 (Closure of debate) shall not be carried in the House, or in a committee of the whole House, unless it appears by the division that not less than one hundred Members voted in the majority in support of the motion.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4622/majority-for-closure/',
    ),
    StandingOrder(
      id: 'commons-42',
      house: 'Commons',
      number: '42',
      title: 'Irrelevance or repetition',
      category: 'Debate & Order',
      summary:
          'The Speaker, or the Chair, after having called the attention of the House, or of the committee, to the conduct of a Member who persists in irrelevance, or tedious repetition either of his or her own arguments or of the arguments used by other Members in debate, may direct him or her to discontinue his or her speech.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4630/irrelevance-or-repetition/',
    ),
    StandingOrder(
      id: 'commons-43',
      house: 'Commons',
      number: '43',
      title: 'Disorderly conduct',
      category: 'Debate & Order',
      summary:
          'The Speaker, or the Chair, shall order any Member whose conduct is grossly disorderly to withdraw immediately from the House during the remainder of that day\'s sitting; and the Serjeant at Arms shall act on such orders as he or she may receive from the Chair in pursuance of this order.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4632/disorderly-conduct/',
    ),
    StandingOrder(
      id: 'commons-44',
      house: 'Commons',
      number: '44',
      title: 'Naming of a Member',
      category: 'Debate & Order',
      summary:
          '(1) Whenever a Member shall have been named by the Speaker, or by the Chair, immediately after the commission of the offence of disregarding the authority of the Chair, or of persistently and wilfully obstructing the business of the House by abusing the rules of the House, or otherwise, the Speaker shall forthwith put the question, on a motion being made, "That such Member be suspended from the service of the House."\n(2) If any Member be suspended under this order, his suspension on the first occasion shall continue for five sitting days, on the second occasion for twenty sitting days, and on any subsequent occasion until the House shall resolve that such suspension do end.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4635/naming-a-member/',
    ),
    StandingOrder(
      id: 'commons-47',
      house: 'Commons',
      number: '47',
      title: 'Time limits on speeches',
      category: 'Debate & Order',
      summary:
          '(1) The Speaker may announce that he or she intends to call Members to speak in a debate subject to a maximum time limit.\n(2) The Speaker may specify different time limits for different categories of Members or different parts of the debate, and may vary any time limit during the course of the debate.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4640/time-limits-on-speeches/',
    ),
    StandingOrder(
      id: 'commons-51',
      house: 'Commons',
      number: '51',
      title: 'Ways and Means motions',
      category: 'Financial Business',
      summary:
          '(1) A motion for a Ways and Means resolution may be made without notice by a Minister of the Crown.\n(2) When any Ways and Means resolution has been agreed to by the House, a bill may be brought in upon such resolution or resolutions, or a clause or clauses making provision pursuant to the resolution may be inserted into a bill.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4650/ways-and-means-motions/',
    ),
    StandingOrder(
      id: 'commons-52',
      house: 'Commons',
      number: '52',
      title: 'Money resolutions',
      category: 'Financial Business',
      summary:
          '(1) The House shall not proceed upon any motion or bill for granting any money, or for releasing or compounding any sum of money owing to the Crown, except upon the recommendation of the Crown signified by a Minister of the Crown.\n(2) Any motion for a money resolution in connection with a public bill shall be put forthwith without amendment or debate if moved immediately after Second Reading.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4652/money-resolutions/',
    ),
    StandingOrder(
      id: 'commons-54',
      house: 'Commons',
      number: '54',
      title: 'Consideration of estimates',
      category: 'Financial Business',
      summary:
          '(1) Three days, before 5th August in each session, shall be allotted for the consideration of estimates, to be known as Estimates Days.\n(2) On an Estimates Day the business under consideration shall be selected by the Liaison Committee and shall be appointed as first government business.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4655/estimates/',
    ),
    StandingOrder(
      id: 'commons-63',
      house: 'Commons',
      number: '63',
      title: 'Allocation of time to bills (Guillotine)',
      category: 'Public Bills',
      summary:
          'When a motion for the allocation of time to a bill has been made by a Minister of the Crown, the question thereon shall be put not later than three hours after the commencement of proceedings on the motion, or at the moment of interruption, whichever is the earlier.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4665/allocation-of-time/',
    ),
    StandingOrder(
      id: 'commons-83A',
      house: 'Commons',
      number: '83A',
      title: 'Programme motions',
      category: 'Public Bills',
      summary:
          '(1) A Minister of the Crown may move a motion (a "programme motion") providing for the timetabling of proceedings on a public bill.\n(2) A programme motion may be moved before or after Second Reading, and the question thereon shall be put forthwith without amendment or debate.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4690/programme-motions/',
    ),
    StandingOrder(
      id: 'commons-83B',
      house: 'Commons',
      number: '83B',
      title: 'Programming committees',
      category: 'Public Bills',
      summary:
          '(1) Where a programme order has been made in respect of a bill committed to a committee of the whole House, there shall be a programming committee consisting of the Chairman of Ways and Means and not more than eight Members nominated by the Speaker.\n(2) The programming committee shall consider the allocation of time for proceedings in committee of the whole House and report its recommendations to the House.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4692/programming-committees/',
    ),
    StandingOrder(
      id: 'commons-84',
      house: 'Commons',
      number: '84',
      title: 'First reading of public bills',
      category: 'Public Bills',
      summary:
          '(1) A bill may be introduced by a Member presenting it at the Table after notice given, or upon an order of the House.\n(2) When a bill is presented or brought from the Lords, the title of the bill shall be read by the Clerk at the Table, and the bill shall then be deemed to have been read the first time and ordered to be printed.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4700/first-reading/',
    ),
    StandingOrder(
      id: 'commons-86',
      house: 'Commons',
      number: '86',
      title: 'Second reading committee',
      category: 'Public Bills',
      summary:
          '(1) A Minister of the Crown may move that a public bill be referred to a Second Reading Committee.\n(2) If not less than twenty Members signify their objection by rising in their places, the motion shall not be made; otherwise the question shall be put forthwith and if agreed to the bill shall be so referred.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4705/second-reading-committee/',
    ),
    StandingOrder(
      id: 'commons-87',
      house: 'Commons',
      number: '87',
      title: 'Committal of public bills',
      category: 'Public Bills',
      summary:
          '(1) When a public bill has been read a second time, it shall stand committed to a Public Bill Committee unless the House orders otherwise.\n(2) A motion to commit a bill to a Committee of the whole House or to a Select Committee may be made by any Member immediately after Second Reading.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4710/committal-of-bills/',
    ),
    StandingOrder(
      id: 'commons-97',
      house: 'Commons',
      number: '97',
      title: 'Scottish Grand Committee',
      category: 'Regional Business',
      summary:
          '(1) There shall be a standing committee designated the Scottish Grand Committee, consisting of all Members representing constituency seats in Scotland.\n(2) The committee may consider bills referred to it, Scottish estimates, and matters relating exclusively to Scotland.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4720/scottish-grand-committee/',
    ),
    StandingOrder(
      id: 'commons-146',
      house: 'Commons',
      number: '146',
      title: 'Select committees (General powers)',
      category: 'Select Committees',
      summary:
          '(1) All select committees shall have power to send for persons, papers and records, to sit notwithstanding any adjournment of the House, to adjourn from place to place, and to report from time to time.\n(2) Select committees shall have power to appoint sub-committees and to refer to such sub-committees any of the matters referred to the committee.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4750/select-committees-powers/',
    ),
    StandingOrder(
      id: 'commons-152',
      house: 'Commons',
      number: '152',
      title: 'Departmental select committees',
      category: 'Select Committees',
      summary:
          '(1) Select committees shall be appointed to examine the expenditure, administration and policy of the principal government departments and associated public bodies.\n(2) Each committee appointed under this order shall consist of not more than eleven Members and shall have the powers specified in Standing Order No. 146.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4760/departmental-select-committees/',
    ),
    StandingOrder(
      id: 'commons-163',
      house: 'Commons',
      number: '163',
      title: 'Motion that the House sit in private',
      category: 'Sittings & Adjournment',
      summary:
          '(1) If any Member rising in his or her place moves "That the House sit in private", the Speaker or Chair shall put the question forthwith without amendment or debate.\n(2) No second motion that the House sit in private shall be made on the same day except by a Minister of the Crown.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4780/sitting-in-private/',
    ),

    // ─── House of Lords ────────────────────────────────────────────────────
    StandingOrder(
      id: 'lords-21',
      house: 'Lords',
      number: '21',
      title: 'Arrangement of business',
      category: 'Public Business',
      summary:
          'Notices of business shall be entered in the Order Paper in the order in which they are received at the Table. Starred Questions and Business of the House motions shall take precedence over legislative business, save as otherwise ordered by the House.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4800/lords-arrangement-of-business/',
    ),
    StandingOrder(
      id: 'lords-30',
      house: 'Lords',
      number: '30',
      title: 'Speeches in the House',
      category: 'Debate & Order',
      summary:
          'No Member of the House shall speak more than once to any motion or amendment, except the Member who moved the motion in reply, or by leave of the House, which leave shall be granted only in exceptional circumstances.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4810/lords-speeches/',
    ),
    StandingOrder(
      id: 'lords-32',
      house: 'Lords',
      number: '32',
      title: 'Asperity of speech to be avoided',
      category: 'Debate & Order',
      summary:
          'To prevent misunderstandings, and for avoiding offensive expressions, all heat, asperity and personal reflection in debate shall be carefully avoided. If any Member speaks words of offense, the Lord Speaker or the House may call the Member to order.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4815/lords-asperity-of-speech/',
    ),
    StandingOrder(
      id: 'lords-46',
      house: 'Lords',
      number: '46',
      title: 'Two stages of a bill on one day',
      category: 'Public Bills',
      summary:
          'No two stages of a bill shall be taken on one day, nor shall a bill be read a third time and passed on the same day it is reported from Committee, unless Standing Orders have been suspended for that purpose.',
      officialUrl:
          'https://erskinemay.parliament.uk/section/4830/lords-two-stages/',
    ),
  ];

  /// Map indexed by lowercase lookup keys (e.g. "24", "commons-24", "so 24").
  static final Map<String, StandingOrder> _byKey = () {
    final map = <String, StandingOrder>{};
    for (final order in allOrders) {
      map[order.id.toLowerCase()] = order;
      map[order.number.toLowerCase()] = order;
      map['so ${order.number}'.toLowerCase()] = order;
      map['so. ${order.number}'.toLowerCase()] = order;
      map['standing order ${order.number}'.toLowerCase()] = order;
      map['standing order no. ${order.number}'.toLowerCase()] = order;
    }
    return map;
  }();

  /// Find a standing order by number or lookup key.
  static StandingOrder? find(String query) {
    final clean = query.trim().toLowerCase();
    return _byKey[clean];
  }
}
