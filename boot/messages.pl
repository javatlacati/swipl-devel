/*  $Id$

    Part of SWI-Prolog
    Designed and implemented by Jan Wielemaker
    E-mail: jan@swi.psy.uva.nl

    Copyright (C) 1997 University of Amsterdam. All rights reserved.
*/

:- module($messages,
	  [ print_message/2		% +Kind, +Term
	  ]).

message(Term) -->
	{var(Term)}, !,
	[ 'Unknown exception term: ~p'-[Term] ].
message(error(ISO, SWI)) -->
	swi_context(SWI),
	term_message(ISO),
	swi_extra(SWI).
message(Term) -->
	[ 'Unknown exception term: ~p'-[Term] ].

term_message(Term) -->
	{var(Term)}, !,
	[ 'Unknown error term: ~p'-[Term] ].
term_message(Term) -->
	iso_message(Term).
term_message(Term) -->
	swi_message(Term).
term_message(Term) -->
	[ 'Unknown error term: ~p'-[Term] ].

iso_message(type_error(evaluable, Actual)) -->
	[ 'Arithmetic: `~p'' is not a function'-[Actual] ].
iso_message(type_error(Expected, Actual)) -->
	[ 'Type error: `~w'' expected, found `~p'''-[Expected, Actual] ].
iso_message(domain_error(Domain, Actual)) -->
	[ 'Domain error: `~w'' expected, found `~p'''-[Domain, Actual] ].
iso_message(instantiation_error) -->
	[ 'Arguments are not sufficiently instantiated' ].
iso_message(representation_error(What)) -->
	[ 'Cannot represent due to `~w'''-[What] ].
iso_message(permission_error(Action, Type, Object)) -->
	[ 'No permission to ~w ~w `~p'''-[Action, Type, Object] ].
iso_message(evaluation_error(Which)) -->
	[ 'Arithmetic: evaluation error: `~p'''-[Which] ].
iso_message(existence_error(procedure, Proc)) -->
	[ 'Undefined procedure: ~p'-[Proc] ],
	{ dwim_predicates(Proc, Dwims) },
	(   {Dwims \== []}
	->  [nl, '    However, there are definitions for:', nl],
	    dwim_message(Dwims)
	;   []
	).
iso_message(existence_error(Type, Object)) -->
	[ '~w `~p'' does not exist'-[Type, Object] ].

dwim_predicates(Module:Name/_Arity, Dwims) :- !,
	findall(Dwim, dwim_predicate(Module:Name, Dwim), Dwims).
dwim_predicates(Name/_Arity, Dwims) :-
	findall(Dwim, dwim_predicate(user:Name, Dwim), Dwims).

dwim_message([]) --> [].
dwim_message([user:Head|T]) --> !,
	{functor(Head, Name, Arity)},
	[ '~t~8|~w/~d'-[Name, Arity], nl ],
	dwim_message(T).
dwim_message([Module:Head|T]) --> !,
	{functor(Head, Name, Arity)},
	[ '~t~8|~w:~w/~d'-[Module, Name, Arity], nl],
	dwim_message(T).
dwim_message([Head|T]) -->
	{functor(Head, Name, Arity)},
	[ '~t~8|~w/~d'-[Name, Arity], nl],
	dwim_message(T).


swi_message(io_error(Op, Stream)) -->
	[ 'I/O error in ~w on stream ~w'-[Op, Stream] ].
swi_message(shell(execute, Cmd)) -->
	[ 'Could not execute `~w'''-[Cmd] ].
swi_message(shell(signal(Sig), Cmd)) -->
	[ 'Caught signal ~d on `~w'''-[Sig, Cmd] ].


swi_context(context(Name/Arity, _Msg)) -->
	{ nonvar(Name)
	}, !,
	[ '~q/~w: '-[Name, Arity] ].
swi_context(_) -->
	[].

swi_extra(context(_, Msg)) -->
	{ atomic(Msg),
	  Msg \== ''
	}, !,
	[ ' (~w)'-[Msg] ].
swi_extra(_) -->
	[].

%	print_message(+Kind, +Term)
%
%	Print an error message using a term as generated by the exception
%	system.


print_message(Level, Term) :-
	message_to_string(Term, Str),
	(   current_predicate(_, user:message_hook(_,_,_)),
	    user:message_hook(Term, Level, Str)
	->  true
	;   source_location(File, Line)
	->  format(user_error, '[WARNING: (~w:~d):~n~t~8|~w]~n',
		   [File, Line, Str])
	;   format(user_error, '[WARNING: ~w]~n', [Str])
	).


%	message_to_string(+Term, -String)
%
%	Translate an error term into a string

message_to_string(Term, Str) :-
        message(Term, Actions, []), !,
        actions_to_format(Actions, Fmt, Args),
        sformat(Str, Fmt, Args).

actions_to_format([], '', []) :- !.
actions_to_format([nl], '', []) :- !.
actions_to_format([Term, nl], Fmt, Args) :- !,
	actions_to_format([Term], Fmt, Args).
actions_to_format([nl|T], Fmt, Args) :- !,
	actions_to_format(T, Fmt0, Args),
	concat('~n', Fmt0, Fmt).
actions_to_format([Fmt0-Args0|Tail], Fmt, Args) :- !,
        actions_to_format(Tail, Fmt1, Args1),
        concat(Fmt0, Fmt1, Fmt),
        append(Args0, Args1, Args).
actions_to_format([Term|Tail], Fmt, Args) :-
	atomic(Term), !,
        actions_to_format(Tail, Fmt1, Args),
	concat(Term, Fmt1, Fmt).
actions_to_format([Term|Tail], Fmt, Args) :-
        actions_to_format(Tail, Fmt1, Args1),
        concat('~w', Fmt1, Fmt),
        append([Term], Args1, Args).

	
