/* Initial beliefs and rules */

all_proposals_received(CNPId,NP) :-              // NP = number of participants
     .count(propose(CNPId,_)[source(_)], NO) &   // number of proposes received
     .count(refuse(CNPId)[source(_)], NR) &      // number of refusals received
     NP = NO + NR.
	
moneyGanied(0).
priceCurrentArticle(0).
article(playstation).
article(guitar).
article(macbook).
article(book).
article(ktm).

/* Initial goals */

!register.
!setup.

/* Plans */

+!register <- .df_register(initiator).

+!setup <- 	
	.findall(Art, article(Art), L);
	.print("I have ", L);
	!setupArticle(L).

+!setupArticle([Head|Tail]) <- 
	?article(Head);
	.random(R);
	-priceCurrentArticle(_);
	+priceCurrentArticle(math.floor((R*100)+20));
	?priceCurrentArticle(Tot);
	.print("Seller try to sell ",Head," expect at least ", Tot);
	!cnp(math.floor((R*100)),Head);
	!setupArticle(Tail).

	
+!setupArticle(Art) <- 
	.print("Sell ended");
	?moneyGanied(Tot);
	.print("My avaible money are ", Tot).
	
// start the CNP
+!cnp(Id,Article)
   <- !call(Id,Article,LP);
      !bid(Id,LP);
      !winner(Id,LO,WAg);
      !result(Id,LO,WAg);
	   .wait(6000);
	  !cleandata(Article).

+!call(Id,Article,LP)
   <- .print("Waiting participants for Article ",Article,"...");
      .wait(2000);  // wait participants introduction
      .df_search("participant",LP);
      .print("Sending CFP to ",LP);
	  ?priceCurrentArticle(Tot);
      .send(LP,tell,cfp(Id,Article,Tot)).
	  
+!bid(Id,LP) // the deadline of the CNP is now + 4 seconds (or all proposals received)
   <- .wait(all_proposals_received(Id,.length(LP)), 4000, _).
   
+!winner(CNPId,LO,WAg)
   :  	.findall(offer(O,A),propose(CNPId,_,O)[source(A)],LO) 
   			& LO \== [] 
   <- ?priceCurrentArticle(Tot);
      .print("Offers are ",LO," i'm exepting at leats ",Tot);
      .max(LO,offer(WOf,WAg));
      .print("Winner is ",WAg," with ",WOf);
	  +sell(WOf).
	  
+!winner(_,_,nowinner).

+!result(_,[],_).

+!result(CNPId,[offer(_,WAg)|T],WAg) 
   <- .send(WAg,tell,accept_proposal(CNPId));
      !result(CNPId,T,WAg).
	  
+!result(CNPId,[offer(_,LAg)|T],WAg) 
   <- .send(LAg,tell,reject_proposal(CNPId));
      !result(CNPId,T,WAg).
	  
+!cleandata(Article) <-
	   ?article(Article);
	   -article(Article).

+sell(Price): moneyGanied(X) <-
	-moneyGanied(_);
	+moneyGanied(X+Price);
	?moneyGanied(Tot);
	.print("My avaible money are ", Tot).
	   
	

