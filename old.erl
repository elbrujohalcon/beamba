-module old.
-export [r/1].

r([]) -> [];
r([X|Xs]) -> r(X, r(Xs)).

r(X, [[C,X]|Xs]) -> [[C+1, X]|Xs];
r(X, Xs) -> [[1, X] | Xs].
