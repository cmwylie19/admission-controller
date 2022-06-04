package main

import (
	"testing"
)

func TestIsKubeNamespace(t *testing.T) {

	kube_ns_1, kube_ns_2 := "kube-system", "kube-public"
	none_kube_ns_1, non_kube_ns_2 := "default", "istio-system"

	if !isKubeNamespace(kube_ns_1) {
		t.Fatalf(`isKubeNamespace("%s") = %t, should be %t.`, kube_ns_1, false, true)
	}

	if !isKubeNamespace(kube_ns_2) {
		t.Fatalf(`isKubeNamespace("%s") = %t, should be %t.`, kube_ns_2, false, true)
	}

	if isKubeNamespace(none_kube_ns_1) {
		t.Fatalf(`isKubeNamespace("%s") = %t, should be %t.`, none_kube_ns_1, false, true)
	}

	if isKubeNamespace(non_kube_ns_2) {
		t.Fatalf(`isKubeNamespace("%s") = %t, should be %t.`, non_kube_ns_2, false, true)
	}
}
