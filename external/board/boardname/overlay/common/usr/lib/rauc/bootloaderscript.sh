#!/bin/sh

getPrimary() {
	#TODO
}
setPrimary() {
	#TODO
}
getState() {
	s=0

	case "$1" in
	A)
		#TODO
		;;
	B)
		#TODO
		;;
	*)
		exit 1
		;;
	esac

	if [ $s -gt 0 ]; then
		echo "bad"
	else
		echo "good"
	fi
}
setState() {
	if [ "$2" = "good" ]; then
		case "$1" in
		A)
			#TODO
			;;
		B)
			#TODO
			;;
		*)
			exit 1
			;;
		esac
	fi
	if [ "$2" = "bad" ]; then
		case "$1" in
		A)
			#TODO
			;;
		B)
			#TODO
			;;
		*)
			exit 1
			;;
		esac
	fi
}

case "$1" in
get-primary)
	getPrimary
	;;
set-primary)
	setPrimary $2
	;;
get-state)
	getState $2
	;;
set-state)
	setState $2 $3
	;;
*)
	exit 1
	;;
esac

exit 0
